defmodule PixelForumWeb.PageController do
  use PixelForumWeb, :controller

  def index(conn, _params) do
    counter = PixelForum.Counter.get()
    render(conn, "index.html", counter: counter)
  end
end
