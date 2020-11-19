defmodule PixelForum.Lobbies.LobbyServer do
  use GenServer, restart: :permanent
  require Logger

  ##############################################################################
  ## Client API

  def start_link(lobby_id),
    do: GenServer.start_link(__MODULE__, lobby_id, name: process_name(lobby_id))

  defp process_name(lobby_id),
    do: {:global, {__MODULE__, lobby_id}}

  ##############################################################################
  ## GenServer callbacks

  @impl true
  def init(lobby_id), do: {:ok, lobby_id}
end
