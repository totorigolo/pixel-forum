defmodule PixelForumWeb.PageLive do
  use PixelForumWeb, :live_view

  alias PixelForum.Lobbies
  alias PixelForum.Images.ImageServer

  @lobby_thumbnails_refresh_interval_ms 10_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Lobbies.subscribe()
      schedule_thumbnails_refresh()
    end

    {:ok, assign(socket, lobbies: list_lobbies(), current_lobby: nil)}
  end

  defp list_lobbies() do
    Enum.map(Lobbies.list_lobbies(), &put_thumbnail_version_into_lobby/1)
    |> sort_lobbies
  end

  defp sort_lobbies(lobbies), do: Enum.sort_by(lobbies, & &1.name)

  defp put_thumbnail_version_into_lobby(lobby) do
    {:ok, version} = ImageServer.get_version(lobby.id)
    Map.put(lobby, :thumbnail_version, version)
  end

  @impl true
  def handle_event("change_lobby", %{"lobby-id" => lobby_id}, socket) do
    # Avoid querying the DB, as users may change lobby often.
    case Enum.find(socket.assigns.lobbies, fn lobby -> lobby.id == lobby_id end) do
      nil ->
        {:noreply, put_flash(socket, :error, "Lobby not found.")}

      current_lobby ->
        {:noreply, assign(socket, current_lobby: current_lobby)}
    end
  end

  defp schedule_thumbnails_refresh(),
    do: Process.send_after(self(), :refresh_thumbnails, @lobby_thumbnails_refresh_interval_ms)

  @impl true
  def handle_info(:refresh_thumbnails, socket) do
    client_lobbies = socket.assigns.lobbies
    new_lobbies = Enum.map(client_lobbies, &put_thumbnail_version_into_lobby/1)

    socket =
      Stream.zip([client_lobbies, new_lobbies])
      |> Enum.reduce(socket, fn {client_lobby, new_lobby}, socket ->
        if client_lobby.thumbnail_version != new_lobby.thumbnail_version do
          push_event(socket, "refresh_thumbnail", %{
            lobby_id: new_lobby.id,
            version: new_lobby.thumbnail_version
          })
        else
          socket
        end
      end)

    schedule_thumbnails_refresh()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:lobby_created, new_lobby}, socket) do
    new_lobby = put_thumbnail_version_into_lobby(new_lobby)
    lobbies = [new_lobby | socket.assigns.lobbies] |> sort_lobbies()
    {:noreply, assign(socket, lobbies: lobbies)}
  end

  @impl true
  def handle_info({:lobby_updated, updated_lobby}, socket) do
    lobbies =
      Enum.map(socket.assigns.lobbies, fn l ->
        if l.id == updated_lobby.id,
          do: put_thumbnail_version_into_lobby(updated_lobby),
          else: l
      end)
      |> sort_lobbies()

    {:noreply, assign(socket, lobbies: lobbies)}
  end

  @impl true
  def handle_info({:lobby_deleted, deleted_lobby}, socket) do
    lobbies = Enum.reject(socket.assigns.lobbies, fn l -> l.id == deleted_lobby.id end)

    if not is_nil(socket.assigns.current_lobby) and socket.assigns.current_lobby.id == deleted_lobby.id do
      {:noreply,
       socket
       |> assign(lobbies: lobbies)
       |> assign(current_lobby: nil)
       |> put_flash(:error, "The current lobby has been deleted.")}
    else
      {:noreply, assign(socket, lobbies: lobbies)}
    end
  end
end
