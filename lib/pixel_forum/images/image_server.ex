defmodule PixelForum.Images.ImageServer do
  use GenServer, restart: :permanent
  alias Phoenix.PubSub

  @type lobby_id :: binary()
  @type version :: non_neg_integer()
  @type user_id :: integer()
  @type coordinates :: MutableImage.coordinates()
  @type color :: MutableImage.color()

  @batch_max_age_ms 2000
  @batch_max_changes 500
  @batch_timeout_ms 200

  defmodule PixelBatch do
    @moduledoc false

    @type monotonic_time :: integer()

    @type t :: %__MODULE__{
            binary: binary(),
            nb_changes: non_neg_integer(),
            created_at: monotonic_time()
          }
    @enforce_keys [:binary, :created_at]
    defstruct [:binary, :created_at, nb_changes: 0]

    @pixel_batch_magic_number 10

    def new(start_version) do
      %__MODULE__{
        binary: <<@pixel_batch_magic_number::8, start_version::40>>,
        created_at: System.monotonic_time(:millisecond)
      }
    end
  end

  defmodule State do
    @moduledoc false
    alias PixelForum.Images.ImageServer

    @type t :: %__MODULE__{
            lobby_id: ImageServer.lobby_id(),
            mutable_image: MutableImage.mutable_image(),
            version: ImageServer.version(),
            png_cache: %{ImageServer.version() => binary()},
            current_batch: ImageServer.PixelBatch.t() | nil,
            batch_timeout_timer: reference() | nil,
            batches: [ImageServer.PixelBatch.t()]
          }
    @enforce_keys [:lobby_id, :mutable_image]
    defstruct [
      :lobby_id,
      :mutable_image,
      :current_batch,
      version: 0,
      png_cache: %{},
      batch_timeout_timer: nil,
      batches: []
    ]
  end

  # Catches when GenServer exits because no process is found, and convert it to
  # an error tuple.
  defmacrop handle_not_found(genserver_call) do
    quote do
      try do
        unquote(genserver_call)
      catch
        :exit, {:noproc, _} -> {:error, :not_found}
      end
    end
  end

  ##############################################################################
  ## Client API

  @doc """
  Starts the GenServer.
  """
  def start_link(lobby_id),
    do: GenServer.start_link(__MODULE__, lobby_id, name: process_name(lobby_id))

  defp process_name(lobby_id),
    do: {:global, {__MODULE__, lobby_id}}

  @doc """
  Get the color of the pixel at the given coordinates.
  """
  @spec get_pixel(lobby_id(), coordinates()) ::
          {:ok, color()} | {:error, :not_found | :invalid_coordinates | :out_of_bounds}
  def get_pixel(lobby_id, coordinates) do
    if not MutableImage.valid_coordinates?(coordinates) do
      {:error, :invalid_coordinates}
    else
      handle_not_found(GenServer.call(process_name(lobby_id), {:get_pixel, coordinates}))
    end
  end

  @doc """
  Change the pixel at the given coordinates to the given color.
  """
  @spec change_pixel(lobby_id(), user_id(), coordinates(), color()) ::
          :ok | {:error, :not_found | :invalid_coordinates | :out_of_bounds | :invalid_color}
  def change_pixel(lobby_id, user_id, coordinates, color) do
    cond do
      not MutableImage.valid_coordinates?(coordinates) ->
        {:error, :invalid_coordinates}

      not MutableImage.valid_color?(color) ->
        {:error, :invalid_color}

      true ->
        handle_not_found(
          GenServer.call(process_name(lobby_id), {:change_pixel, user_id, coordinates, color})
        )
    end
  end

  @doc """
  Returns the image as binary encoded in PNG format.
  """
  @spec as_png(lobby_id()) :: {:ok, version(), binary()} | {:error, :not_found}
  def as_png(lobby_id) do
    handle_not_found(GenServer.call(process_name(lobby_id), :as_png))
  end

  @doc """
  Returns the version of the image.
  """
  @spec get_version(lobby_id()) :: {:ok, version()} | {:error, :not_found}
  def get_version(lobby_id) do
    handle_not_found(GenServer.call(process_name(lobby_id), :get_version))
  end

  @spec reset_image(lobby_id()) :: :ok | {:error, :not_found}
  def reset_image(lobby_id) do
    handle_not_found(GenServer.call(process_name(lobby_id), :reset_image))
  end

  ##############################################################################
  ## GenServer callbacks

  @impl true
  @spec init(lobby_id()) :: {:ok, State.t()}
  def init(lobby_id) do
    {:ok, mutable_image} = new_mutable_image()
    {:ok, %State{lobby_id: lobby_id, mutable_image: mutable_image}}
  end

  @impl true
  def handle_call({:get_pixel, coordinates}, _from, %State{} = state) do
    case MutableImage.get_pixel(state.mutable_image, coordinates) do
      {:ok, color} ->
        {:reply, {:ok, color}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:change_pixel, user_id, coordinates, color}, _from, %State{} = state) do
    case MutableImage.change_pixel(state.mutable_image, coordinates, color) do
      :ok ->
        new_state = pixel_changed(state, user_id, coordinates, color)
        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:as_png, _from, %State{mutable_image: mutable_image} = state) do
    cache =
      Map.put_new_lazy(state.png_cache, state.version, fn ->
        {:ok, png} = MutableImage.as_png(mutable_image)
        png
      end)

    png = Map.get(cache, state.version)
    {:reply, {:ok, state.version, png}, %{state | png_cache: cache}}
  end

  @impl true
  def handle_call(:get_version, _from, %State{version: version} = state) do
    {:reply, {:ok, version}, state}
  end

  @impl true
  def handle_call(:reset_image, _from, %State{batch_timeout_timer: timer} = state) do
    if timer, do: Process.cancel_timer(timer)
    {:ok, new_image} = new_mutable_image()

    new_version = case state.current_batch do
      nil -> state.version
      batch -> state.version - batch.nb_changes
    end

    PubSub.broadcast(PixelForum.PubSub, "image:" <> state.lobby_id, :image_reset)

    {:reply, :ok,
     state
     |> Map.replace!(:mutable_image, new_image)
     |> Map.replace!(:version, new_version)
     |> Map.replace!(:png_cache, %{})
     |> Map.replace!(:current_batch, nil)
     |> Map.replace!(:batch_timeout_timer, nil)
     |> Map.replace!(:batches, [])}
  end

  @impl true
  def handle_info(:batch_timeout, %State{} = state) do
    {:noreply, state |> seal_current_batch()}
  end

  @impl true
  def handle_info(:batch_timeout, %State{current_batch: nil} = state) do
    raise "Invalid state: received :batch_timeout but no current batch. State: #{state}"
  end

  ##############################################################################
  ## Private functions

  defp new_mutable_image(), do: MutableImage.new(512, 512)

  @spec pixel_changed(State.t(), user_id(), coordinates(), color()) ::
          State.t()
  defp pixel_changed(state, _user_id, coordinates, color) do
    PubSub.broadcast(
      PixelForum.PubSub,
      "image:" <> state.lobby_id,
      {:pixel_changed, {coordinates, color}}
    )

    state
    |> Map.replace!(:version, state.version + 1)
    |> handle_batch_expiration()
    |> add_to_current_batch(coordinates, color)
    |> Map.replace!(:png_cache, %{})
  end

  @spec handle_batch_expiration(State.t()) :: State.t()
  defp handle_batch_expiration(%State{current_batch: nil} = state), do: state

  defp handle_batch_expiration(%State{current_batch: current_batch} = state) do
    if batch_expired?(current_batch), do: seal_current_batch(state), else: state
  end

  @spec seal_current_batch(State.t()) :: State.t()
  defp seal_current_batch(%State{current_batch: current_batch} = state) do
    PubSub.broadcast(
      PixelForum.PubSub,
      "image:" <> state.lobby_id,
      {:new_change_batch, current_batch.binary}
    )

    state
    |> Map.replace!(:batches, [current_batch | state.batches] |> Enum.take(10))
    |> Map.replace!(:current_batch, nil)
  end

  @spec add_to_current_batch(State.t(), coordinates(), color()) :: State.t()
  defp add_to_current_batch(%State{current_batch: nil} = state, coordinates, color) do
    state
    |> Map.replace!(:current_batch, PixelBatch.new(state.version))
    |> add_to_current_batch(coordinates, color)
  end

  defp add_to_current_batch(
         %State{
           current_batch: %PixelBatch{binary: binary, nb_changes: nb_changes},
           batch_timeout_timer: timer
         } = state,
         {x, y},
         {r, g, b}
       ) do
    if timer, do: Process.cancel_timer(timer)

    # TODO: put timeout into state to avoid having multiple of them

    state
    |> Map.replace!(
      :batch_timeout_timer,
      Process.send_after(self(), :batch_timeout, @batch_timeout_ms)
    )
    |> Map.replace!(:current_batch, %{
      state.current_batch
      | binary: binary <> <<x::16, y::16, r::8, g::8, b::8>>,
        nb_changes: nb_changes + 1
    })
  end

  @spec batch_expired?(PixelBatch.t()) :: boolean()
  defp batch_expired?(batch) do
    batch.nb_changes > @batch_max_changes || now() - batch.created_at > @batch_max_age_ms
  end

  defp now(), do: System.monotonic_time(:millisecond)
end
