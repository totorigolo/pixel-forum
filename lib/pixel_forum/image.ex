defmodule PixelForum.Image do
  use GenServer

  @type state :: {:mutable_image, MutableImage.mutable_image()}

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
    GenServer.call(__MODULE__, {:change_pixel, coordinate, color})
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
  @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    {:ok, mutable_image} = MutableImage.new(512, 512)
    {:ok, {:mutable_image, mutable_image}}
  end

  @impl true
  def handle_call({:change_pixel, coordinate, color}, _from, {:mutable_image, mutable_image} = state) do
    :ok = MutableImage.change_pixel(mutable_image, coordinate, color)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:as_png, _from, {:mutable_image, mutable_image} = state) do
    {:ok, png} = MutableImage.as_png(mutable_image)
    {:reply, {:ok, png}, state}
  end
end
