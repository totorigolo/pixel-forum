defmodule PixelForumWeb.ImageController do
  use PixelForumWeb, :controller

  def get_image(conn, %{"id" => "0" = id}) do
    {:ok, png} = PixelForum.Image.as_png()
    send_download(conn, {:binary, png}, filename: "image_#{id}.png", disposition: :inline)
  end

  def get_image(conn, %{"id" => id}) do
    text(conn, id)
  end
end
