defmodule PixelForum.Lobbies.LobbySpawner do
  use GenServer,
    # Once the job is done, should not be restarted.
    restart: :transient

  require Logger

  def start_link(opts) do
    opts = opts ++ [name: __MODULE__]
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(state) do
    Logger.debug("PixelForum.Lobbies.LobbySpawner started.")

    # We know that LobbySupervisor is running thanks to the supervisor above,
    # using the :rest_for_one strategy.
    PixelForum.Lobbies.ForumSupervisor.start_all_lobbies()

    Logger.info("Spawned lobby servers.")

    {:ok, state}
  end
end
