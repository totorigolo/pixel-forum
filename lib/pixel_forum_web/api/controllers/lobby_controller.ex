defmodule PixelForumWeb.API.LobbyController do
  use PixelForumWeb, :controller

  def get_pixel(conn, %{"id" => lobby_id, "x" => x, "y" => y}) do
    coordinates = {String.to_integer(x), String.to_integer(y)}

    case PixelForum.Images.ImageServer.get_pixel(lobby_id, coordinates) do
      {:ok, {r, g, b}} -> json(conn, %{r: r, g: g, b: b})
      {:error, reason} -> handle_error(conn, reason)
    end
  end

  def set_pixel(conn, %{"id" => lobby_id, "x" => x, "y" => y, "r" => r, "g" => g, "b" => b}) do
    user_id = get_claims!(conn)["sub"]

    coordinates = {String.to_integer(x), String.to_integer(y)}
    color = {r, g, b}

    # TODO: Rate-limiting + unit tests

    case PixelForum.Images.ImageServer.change_pixel(lobby_id, user_id, coordinates, color) do
      :ok -> json(conn, nil)
      {:error, reason} -> handle_error(conn, reason)
    end
  end

  defp handle_error(conn, :invalid_color), do: send_error(conn, 400, "Invalid color.")
  defp handle_error(conn, :invalid_coordinates), do: send_error(conn, 400, "Invalid coordinates.")
  defp handle_error(conn, :not_found), do: send_error(conn, 404, "Lobby not found.")
  defp handle_error(conn, :out_of_bounds), do: send_error(conn, 404, "Coordinates out of bounds.")

  defp send_error(conn, status, message) when is_binary(message) do
    conn
    |> put_status(status)
    |> json(%{error: %{code: status, message: message}})
  end
end
