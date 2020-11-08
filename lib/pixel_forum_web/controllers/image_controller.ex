defmodule PixelForumWeb.ImageController do
  use PixelForumWeb, :controller

  def get_image(conn, %{"id" => "0" = id, "version" => version}) do
    get_image(conn, String.to_integer(id), String.to_integer(version))
  end

  def get_image(conn, %{"id" => id, "version" => version}) do
    conn
    |> put_status(404)
    |> text("Not found: #{id}-#{version}")
  end

  defp get_image(conn, id, version) when is_integer(id) and is_integer(version) do
    {:ok, png} = PixelForum.Image.as_png()
    send_download(conn, {:binary, png}, filename: "image_#{id}_#{version}.png", disposition: :inline)
  end
end
