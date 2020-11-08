defmodule PixelForum.Image do
  use GenServer

  defmodule State do
    @type t :: %__MODULE__{
            mutable_image: MutableImage.mutable_image(),
            version: non_neg_integer()
          }
    @enforce_keys [:mutable_image]
    defstruct [:mutable_image, version: 0]
  end

  ##############################################################################
  ## Client API

  @doc """
  Starts the counter.
  """
  def start_link(opts) do
    opts = opts ++ [name: __MODULE__]
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Increment the counter by the given amount, returning the new value.
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
        new_state = %{state | version: state.version + 1}
        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:as_png, _from, %State{mutable_image: mutable_image} = state) do
    {:ok, png} = MutableImage.as_png(mutable_image)
    {:reply, {:ok, png}, state}
  end
end
