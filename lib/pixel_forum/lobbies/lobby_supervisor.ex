defmodule PixelForum.Lobbies.LobbySupervisor do
  use Supervisor
  require Logger

  def start_link(lobby_id),
    do: Supervisor.start_link(__MODULE__, lobby_id, name: get_name(lobby_id))

  def get_name(lobby_id),
    do: {:via, Registry, {PixelForum.Forum.LobbyRegistry, {__MODULE__, lobby_id}}}

  @impl true
  def init(lobby_id) do
    Logger.debug("PixelForum.Lobbies.LobbySupervisor started for #{lobby_id}.")

    children = [
      {PixelForum.Lobbies.LobbyServer, lobby_id},
      {PixelForum.Images.ImageServer, lobby_id}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
