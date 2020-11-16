defmodule PixelForum.Lobbies.LobbySupervisor do
  use Supervisor
  require Logger

  def start_link(lobby_id),
    do: Supervisor.start_link(__MODULE__, lobby_id)

  @impl true
  def init(lobby_id) do
    children = [
      {PixelForum.Lobbies.LobbyServer, lobby_id},
      {PixelForum.Images.ImageServer, lobby_id},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
