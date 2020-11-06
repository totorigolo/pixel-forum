defmodule PixelForum.Image do
  use GenServer

  @type counter_type :: integer
  @type state :: integer

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
  Returns the value of the counter.
  """
  @spec get :: counter_type
  def get() do
    GenServer.call(__MODULE__, {:get})
  end

  @doc """
  Increment the counter by the given amount, returning the new value.
  """
  @spec increment(counter_type) :: counter_type
  def increment(amount) when is_integer(amount) do
    GenServer.call(__MODULE__, {:increment, amount})
  end

  ##############################################################################
  ## GenServer callbacks

  @impl true
  @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    {:ok, 0}
  end

  @impl true
  @spec handle_call({:get}, any, state) :: {:reply, counter_type, state}
  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  @spec handle_call({:increment, counter_type}, any, state) :: {:reply, counter_type, state}
  def handle_call({:increment, amount}, _from, state) do
    {:ok, new_value} = MutableImage.Image.add(state, amount)
    {:reply, new_value, new_value}
  end
end
