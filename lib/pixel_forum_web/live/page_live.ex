defmodule PixelForumWeb.PageLive do
  use PixelForumWeb, :live_view

  alias PixelForum.Lobbies
  alias PixelForum.Images.ImageServer

  @lobby_thumbnails_refresh_interval_ms 10_000

  @impl true
  def mount(_params, _session, socket) do
    schedule_thumbnails_refresh()
    {:ok, assign(socket, lobbies: list_lobbies(), current_lobby: nil)}
  end

  defp list_lobbies(), do: Enum.map(Lobbies.list_lobbies(), &put_thumbnail_version_into_lobby/1)

  defp put_thumbnail_version_into_lobby(lobby),
    do: Map.put(lobby, :thumbnail_version, ImageServer.get_version!(lobby.id))

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
end
