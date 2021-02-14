defmodule PixelForum.Lobbies.LobbySupervisor do
  use Supervisor
  require Logger

  ##############################################################################
  ## Client API

  def start_link(lobby_id),
    do: Supervisor.start_link(__MODULE__, lobby_id, name: process_name(lobby_id))

  defp process_name(lobby_id),
    do: {:via, Registry, {PixelForum.Forum.LobbyRegistry, {__MODULE__, lobby_id}}}

  ##############################################################################
  ## GenServer callbacks

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
