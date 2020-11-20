defmodule PixelForumWeb.PageLive do
  use PixelForumWeb, :live_view

  alias PixelForum.Lobbies

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, lobbies: Lobbies.list_lobbies(), current_lobby: nil)}
  end

  @impl true
  def handle_event("change_lobby", %{"lobby-id" => lobby_id}, socket) do
    # Avoid querying the DB, as users may change lobby too often.
    case Enum.find(socket.assigns.lobbies, fn lobby -> lobby.id == lobby_id end) do
      nil ->
        {:noreply, put_flash(socket, :error, "Lobby not found.")}

      current_lobby ->
        {:noreply, assign(socket, current_lobby: current_lobby)}
    end
  end
end
