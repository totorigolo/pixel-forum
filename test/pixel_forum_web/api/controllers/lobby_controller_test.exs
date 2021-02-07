defmodule PixelForumWeb.API.LobbyControllerTest do
  use PixelForumWeb.ApiCase, async: true

  alias PixelForum.Lobbies

  @create_attrs %{name: "lobby name"}

  describe "get_pixel/2" do
    setup [:create_lobby]

    test "returns pixel color when correct coordinates", %{conn: conn, lobby: lobby} do
      conn = get(conn, Routes.api_lobby_path(conn, :get_pixel, lobby.id, 0, 0))
      assert %{"r" => 0, "g" => 0, "b" => 0} == json_response(conn, 200)
    end

    test "returns 404 error when invalid lobby ID", %{conn: conn} do
      conn = get(conn, Routes.api_lobby_path(conn, :get_pixel, "invalid", 0, 0))
      assert error_json(404, "Lobby not found.") == json_response(conn, 404)
    end

    test "returns 400 error when illegal coordinates", %{conn: conn, lobby: lobby} do
      conn = get(conn, Routes.api_lobby_path(conn, :get_pixel, lobby.id, -10, 0))
      assert error_json(400, "Invalid coordinates.") == json_response(conn, 400)
    end

    test "returns 404 error when coordinates out of bounds", %{conn: conn, lobby: lobby} do
      conn = get(conn, Routes.api_lobby_path(conn, :get_pixel, lobby.id, 10_000, 0))
      assert error_json(404, "Coordinates out of bounds.") == json_response(conn, 404)
    end
  end

  defp create_lobby(_) do
    %{lobby: fixture(:lobby)}
  end

  def fixture(:lobby) do
    {:ok, lobby} = Lobbies.create_lobby(@create_attrs)
    lobby
  end

  defp error_json(status, message), do: %{"error" => %{"code" => status, "message" => message}}
end
