defmodule PixelForum.Images.Image do
  use GenServer
  alias Phoenix.PubSub

  defmodule State do
    @moduledoc "State of the GenServer."

    @type t :: %__MODULE__{
            mutable_image: MutableImage.mutable_image(),
            version: non_neg_integer(),
            png_cache: %{non_neg_integer() => binary()}
          }
    @enforce_keys [:mutable_image]
    defstruct [:mutable_image, version: 0, png_cache: %{}]
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
  @spec change_pixel(MutableImage.coordinate(), MutableImage.color()) :: :ok | {:error, atom}
  def change_pixel(coordinate, color) do
    cond do
      not MutableImage.valid_coordinate?(coordinate) ->
        {:error, :invalid_coordinate}

      not MutableImage.valid_color?(color) ->
        {:error, :invalid_color}

      true ->
        GenServer.call(__MODULE__, {:change_pixel, coordinate, color})
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
  def handle_call({:change_pixel, coordinate, color}, _from, %State{} = state) do
    case MutableImage.change_pixel(state.mutable_image, coordinate, color) do
      :ok ->
        PubSub.broadcast(PixelForum.PubSub, "image:lobby", {:pixel_changed, {coordinate, color}})
        new_state = %{state | version: state.version + 1, png_cache: %{}}
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
end
