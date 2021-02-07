defmodule PixelForumWeb.LobbyController do
  use PixelForumWeb, :controller

  alias PixelForum.Lobbies
  alias PixelForum.Lobbies.Lobby

  def get_image(conn, %{"id" => lobby_id}) do
    case PixelForum.Images.ImageServer.as_png(lobby_id) do
      {:ok, version, png} ->
        filename = "image_#{lobby_id}_#{version}.png"

        conn
        |> Plug.Conn.put_resp_header("cache-control", "no-store")
        |> send_download({:binary, png}, filename: filename, disposition: :inline)

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{message: "Lobby not found: #{lobby_id}."})
    end
  end

  def reset_image(conn, %{"id" => lobby_id}) do
    {:ok, lobby} = Lobbies.reset_lobby_image(lobby_id)

    conn
    |> put_flash(:info, "Lobby image reset successfully.")
    |> redirect(to: Routes.lobby_path(conn, :show, lobby))
  end

  def index(conn, _params) do
    lobbies = Lobbies.list_lobbies()
    render(conn, "index.html", lobbies: lobbies)
  end

  def new(conn, _params) do
    changeset = Lobbies.change_lobby(%Lobby{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"lobby" => lobby_params}) do
    case Lobbies.create_lobby(lobby_params) do
      {:ok, lobby} ->
        conn
        |> put_flash(:info, "Lobby created successfully.")
        |> redirect(to: Routes.lobby_path(conn, :show, lobby))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    lobby = Lobbies.get_lobby!(id)
    render(conn, "show.html", lobby: lobby)
  end

  def edit(conn, %{"id" => id}) do
    lobby = Lobbies.get_lobby!(id)
    changeset = Lobbies.change_lobby(lobby)
    render(conn, "edit.html", lobby: lobby, changeset: changeset)
  end

  def update(conn, %{"id" => id, "lobby" => lobby_params}) do
    lobby = Lobbies.get_lobby!(id)

    case Lobbies.update_lobby(lobby, lobby_params) do
      {:ok, lobby} ->
        conn
        |> put_flash(:info, "Lobby updated successfully.")
        |> redirect(to: Routes.lobby_path(conn, :show, lobby))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", lobby: lobby, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    lobby = Lobbies.get_lobby!(id)
    {:ok, _lobby} = Lobbies.delete_lobby(lobby)

    conn
    |> put_flash(:info, "Lobby deleted successfully.")
    |> redirect(to: Routes.lobby_path(conn, :index))
  end
end
