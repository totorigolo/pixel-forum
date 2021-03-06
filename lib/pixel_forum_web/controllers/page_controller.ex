defmodule PixelForumWeb.PageController do
  use PixelForumWeb, :controller

  alias PixelForum.Lobbies

  def index(conn, _params) do
    lobbies = Lobbies.list_lobbies()

    render(conn, "index.html", lobbies: lobbies)
  end

  def keep_alive(conn, _params) do
    text(conn, "ok")
  end
end
