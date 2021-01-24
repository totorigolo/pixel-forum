defmodule PixelForum.Forum.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Start the registry for storing lobby supervisor PIDs and names to ensure uniqueness.
      {Registry, keys: :unique, name: PixelForum.Forum.LobbyRegistry},
      # Start the dynamic supervisor for lobbies.
      {DynamicSupervisor, name: PixelForum.Forum.LobbySupervisor, strategy: :one_for_one},
      # Start the registry, responsible for starting and stopping lobbies.
      PixelForum.Forum.LobbyManager,
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
