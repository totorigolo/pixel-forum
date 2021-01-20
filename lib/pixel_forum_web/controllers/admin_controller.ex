defmodule PixelForumWeb.AdminController do
  use PixelForumWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
