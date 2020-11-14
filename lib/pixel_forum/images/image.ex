defmodule PixelForum.Images.Image do
  use GenServer
  alias Phoenix.PubSub

  @type version :: non_neg_integer()
  @type user_id :: integer()
  @type coordinate :: MutableImage.coordinate()
  @type color :: MutableImage.color()

  @batch_max_age_ms 2000
  @batch_max_changes 500
  @batch_timeout_ms 200

  defmodule Batch do
    @moduledoc false
    alias PixelForum.Images.Image

    @type monotonic_time :: integer()

    @type t :: %__MODULE__{
            binary: binary(),
            nb_changes: non_neg_integer(),
            created_at: monotonic_time()
          }
    @enforce_keys [:binary, :created_at]
    defstruct [:binary, :created_at, nb_changes: 0]

    def new(start_version) do
      %__MODULE__{
        binary: <<start_version::40>>,
        created_at: System.monotonic_time(:millisecond)
      }
    end
  end

  defmodule State do
    @moduledoc false
    alias PixelForum.Images.Image

    @type t :: %__MODULE__{
            mutable_image: MutableImage.mutable_image(),
            version: Image.version(),
            png_cache: %{Image.version() => binary()},
            current_batch: Image.Batch.t() | nil,
            batch_timeout_timer: reference() | nil,
            batches: [Image.Batch.t()]
          }
    @enforce_keys [:mutable_image]
    defstruct [
      :mutable_image,
      :current_batch,
      version: 0,
      png_cache: %{},
      batch_timeout_timer: nil,
      batches: []
    ]
  end

  ##############################################################################
  ## Client API

  @doc """
  Starts the GenServer.
  """
  def start_link(opts) do
    opts = opts ++ [name: __MODULE__]
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Change the pixel at the given coordinates to the given color.
  """
  @spec change_pixel(user_id(), coordinate(), color()) ::
          :ok | {:error, atom}
  def change_pixel(user_id, coordinate, color) do
    cond do
      not MutableImage.valid_coordinate?(coordinate) ->
        {:error, :invalid_coordinate}

      not MutableImage.valid_color?(color) ->
        {:error, :invalid_color}

      true ->
        GenServer.call(__MODULE__, {:change_pixel, user_id, coordinate, color})
    end
  end

  @doc """
  Returns the image as binary encoded in PNG format.
  """
  @spec as_png() :: {:ok, binary()} | {:error, atom}
  def as_png() do
    GenServer.call(__MODULE__, :as_png)
  end

  ##############################################################################
  ## GenServer callbacks

  @impl true
  @spec init(:ok) :: {:ok, State.t()}
  def init(:ok) do
    {:ok, mutable_image} = MutableImage.new(512, 512)
    {:ok, %State{mutable_image: mutable_image}}
  end

  @impl true
  def handle_call({:change_pixel, user_id, coordinate, color}, _from, %State{} = state) do
    case MutableImage.change_pixel(state.mutable_image, coordinate, color) do
      :ok ->
        new_state = pixel_changed(state, user_id, coordinate, color)
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
    {:reply, {:ok, png}, %{state | png_cache: cache}}
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

  @spec pixel_changed(State.t(), user_id(), coordinate(), color()) ::
          State.t()
  defp pixel_changed(state, _user_id, coordinate, color) do
    PubSub.broadcast(PixelForum.PubSub, "image:lobby", {:pixel_changed, {coordinate, color}})

    state
    |> Map.replace!(:version, state.version + 1)
    |> handle_batch_expiration()
    |> add_to_current_batch(coordinate, color)
    |> Map.replace!(:png_cache, %{})
  end

  @spec handle_batch_expiration(State.t()) :: State.t()
  defp handle_batch_expiration(%State{current_batch: nil} = state), do: state

  defp handle_batch_expiration(%State{current_batch: current_batch} = state) do
    if batch_expired?(current_batch), do: seal_current_batch(state), else: state
  end

  @spec seal_current_batch(State.t()) :: State.t()
  defp seal_current_batch(%State{current_batch: current_batch} = state) do
    PubSub.broadcast(PixelForum.PubSub, "image:lobby", {:new_change_batch, current_batch.binary})

    state
    |> Map.replace!(:batches, [current_batch | state.batches] |> Enum.take(10))
    |> Map.replace!(:current_batch, nil)
  end

  @spec add_to_current_batch(State.t(), coordinate(), color()) :: State.t()
  defp add_to_current_batch(%State{current_batch: nil} = state, coordinates, color) do
    state
    |> Map.replace!(:current_batch, Batch.new(state.version))
    |> add_to_current_batch(coordinates, color)
  end

  defp add_to_current_batch(
         %State{
           current_batch: %Batch{binary: binary, nb_changes: nb_changes},
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

  @spec batch_expired?(Batch.t()) :: boolean()
  defp batch_expired?(batch) do
    now = System.monotonic_time(:millisecond)
    batch.nb_changes > @batch_max_changes || batch.created_at - now > @batch_max_age_ms
  end
end