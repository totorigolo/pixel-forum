defmodule PixelForum.Lobbies.ForumSupervisor do
  use DynamicSupervisor
  require Logger

  alias PixelForum.Lobbies
  alias PixelForum.Lobbies.Lobby
  alias PixelForum.Lobbies.LobbySupervisor

  def start_link(init_arg),
    do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_lobby(lobby_id) do
    Logger.info("Starting lobby: #{lobby_id}")

    {:ok, _} = DynamicSupervisor.start_child(__MODULE__, {LobbySupervisor, lobby_id})
  end

  def start_all_lobbies() do
    Enum.each(Lobbies.list_lobbies(), fn %Lobby{id: lobby_id} ->
      start_lobby(lobby_id)
    end)
  end

  def terminate_lobby(lobby_id) do
    raise "not implemented: terminate_lobby(#{lobby_id})"
    # Supervisor.terminate_child(__MODULE__, pid)
  end
end
