defmodule PixelForum.Lobbies.LobbyServer do
  use GenServer, restart: :permanent
  require Logger

  alias Horde.Registry

  ##############################################################################
  ## Client API

  def start_link(lobby_id) do
    case GenServer.start_link(__MODULE__, lobby_id, name: process_name(lobby_id)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("LobbyServer for #{lobby_id} already started at #{inspect(pid)}.")
        :ignore
    end
  end

  defp process_name(lobby_id),
    do: {:via, Registry, {PixelForum.Forum.LobbyRegistry, {__MODULE__, lobby_id}}}

  ##############################################################################
  ## GenServer callbacks

  @impl true
  def init(lobby_id), do: {:ok, lobby_id}
end
