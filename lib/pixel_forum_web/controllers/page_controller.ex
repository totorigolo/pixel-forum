defmodule PixelForumWeb.PageController do
  use PixelForumWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", counter: PixelForum.Counter.get())
  end
end
