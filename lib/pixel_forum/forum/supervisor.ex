defmodule PixelForum.Forum.Supervisor do
  use Supervisor

  def start_link(_), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(_init_arg) do
    children = [
      {Horde.Registry, name: PixelForum.Forum.LobbyRegistry, keys: :unique, members: :auto},
      {Horde.DynamicSupervisor,
       name: PixelForum.Forum.LobbySupervisor,
       strategy: :one_for_one,
       # Automatically use every nodes in the cluster.
       members: :auto},
      # Start the registry, responsible for starting and stopping lobbies.
      PixelForum.Forum.LobbyManager
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
