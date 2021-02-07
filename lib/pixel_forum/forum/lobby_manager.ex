defmodule PixelForum.Forum.LobbyManager do
  use GenServer, restart: :permanent

  require Logger

  alias PixelForum.Forum
  alias PixelForum.Lobbies
  alias PixelForum.Lobbies.Lobby

  ##############################################################################
  ## Client API

  def start_link(opts) do
    opts = opts ++ [name: __MODULE__, hibernate_after: 5_000]
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def start_lobby(lobby_id) do
    GenServer.call(__MODULE__, {:start_lobby, lobby_id})
  end

  def stop_lobby(lobby_id) do
    GenServer.call(__MODULE__, {:stop_lobby, lobby_id})
  end

  ##############################################################################
  ## GenServer callbacks

  @impl true
  def init(:ok) do
    Logger.debug("PixelForum.Forum.LobbyManager started.")

    Lobbies.subscribe()
    Logger.info("Lobby registry subscribed to \"lobbies\" topic.")

    start_all_lobbies!()
    Logger.info("Spawned lobby supervisors.")

    {:ok, nil}
  end

  @impl true
  def handle_call({:start_lobby, lobby_id}, _from, state) do
    {:reply, start_lobby_(lobby_id), state}
  end

  @impl true
  def handle_call({:stop_lobby, lobby_id}, _from, state) do
    {:reply, stop_lobby_(lobby_id), state}
  end

  ##############################################################################
  ## PubSub events

  @impl true
  def handle_info({:lobby_created, _lobby}, state) do
    # The lobby must have already been started before this event has been sent,
    # so we do nothing.
    {:noreply, state}
  end

  @impl true
  def handle_info({:lobby_updated, _lobby}, state), do: {:noreply, state}

  @impl true
  def handle_info({:lobby_deleted, %Lobby{id: lobby_id}}, state) do
    stop_lobby_(lobby_id)
    {:noreply, state}
  end

  @impl true
  def handle_info({:lobby_image_reset, _lobby}, state), do: {:noreply, state}

  ##############################################################################
  ## Private functions

  defp start_lobby_(lobby_id) do
    result = DynamicSupervisor.start_child(Forum.LobbySupervisor, {Lobbies.LobbySupervisor, lobby_id})

    case result do
      {:ok, pid} ->
        Logger.info("Started lobby supervisor for #{lobby_id} at #{inspect pid}.")

      {:error, {:already_started, pid}} ->
        Logger.warn("Tried to start lobby #{lobby_id} which is already started at #{inspect pid}.")

      {:error, reason} ->
        Logger.error("Failed to start lobby #{lobby_id}: #{reason}")
    end

    result
  end

  defp start_all_lobbies!() do
    Enum.each(Lobbies.list_lobbies(), fn %Lobby{id: lobby_id} ->
      start_lobby_(lobby_id)
    end)
  end

  defp stop_lobby_(lobby_id) do
    lobby_sup_name = {PixelForum.Lobbies.LobbySupervisor, lobby_id}
    [{pid, nil}] = Registry.lookup(PixelForum.Forum.LobbyRegistry, lobby_sup_name)
    DynamicSupervisor.terminate_child(Forum.LobbySupervisor, pid)
  end
end
