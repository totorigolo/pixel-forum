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

  describe "set_pixel/2" do
    setup [:create_lobby, :authenticate_api]

    @valid_color %{"r" => 255, "g" => 128, "b" => 0}
    @invalid_color %{"r" => 255, "g" => 128, "b" => 10_000}

    test "replies 200 when correct parameters", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.api_lobby_path(conn, :set_pixel, lobby.id, 0, 0), @valid_color)
      assert nil == json_response(conn, 200)
    end

    test "returns 400 error when color is invalid", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.api_lobby_path(conn, :set_pixel, lobby.id, 0, 0), @invalid_color)
      assert error_json(400, "Invalid color.") == json_response(conn, 400)
    end

    test "returns 404 error when invalid lobby ID", %{conn: conn} do
      conn = put(conn, Routes.api_lobby_path(conn, :set_pixel, "invalid", 0, 0), @valid_color)
      assert error_json(404, "Lobby not found.") == json_response(conn, 404)
    end

    test "returns 400 error when illegal coordinates", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.api_lobby_path(conn, :set_pixel, lobby.id, -10, 0), @valid_color)
      assert error_json(400, "Invalid coordinates.") == json_response(conn, 400)
    end

    test "returns 404 error when coordinates out of bounds", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.api_lobby_path(conn, :set_pixel, lobby.id, 10_000, 0), @valid_color)
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

  defp authenticate_api(%{conn: conn}) do
    alias PixelForum.Users
    {:ok, token} = Users.create_access_token(%Users.User{id: 0})

    conn = put_req_header(conn, "authorization", "Bearer " <> token)
    {:ok, jwt: token, conn: conn}
  end
end
