defmodule PixelForumWeb.LobbyController do
  use PixelForumWeb, :controller

  alias PixelForum.Lobbies
  alias PixelForum.Lobbies.Lobby

  def get_image(conn, %{"lobby" => lobby_id}) do
    case PixelForum.Images.ImageServer.as_png(lobby_id) do
      {:ok, version, png} ->
        filename = "image_#{lobby_id}_#{version}.png"
        send_download(conn, {:binary, png}, filename: filename, disposition: :inline)

      {:error, _reason} ->
        conn
        |> put_status(404)
        |> text("Lobby not found: #{lobby_id}")
    end
  end

  ##############################################################################
  ## Below are the auto-generated routes, to be eventually deleted if not needed.

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
