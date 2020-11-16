defmodule PixelForumWeb.LobbyControllerTest do
  use PixelForumWeb.ConnCase

  alias PixelForum.Lobbies

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:lobby) do
    {:ok, lobby} = Lobbies.create_lobby(@create_attrs)
    lobby
  end

  describe "index" do
    test "lists all lobbies", %{conn: conn} do
      conn = get(conn, Routes.lobby_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Lobbies"
    end
  end

  describe "new lobby" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.lobby_path(conn, :new))
      assert html_response(conn, 200) =~ "New Lobby"
    end
  end

  describe "create lobby" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.lobby_path(conn, :create), lobby: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.lobby_path(conn, :show, id)

      conn = get(conn, Routes.lobby_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Lobby"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.lobby_path(conn, :create), lobby: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Lobby"
    end
  end

  describe "edit lobby" do
    setup [:create_lobby]

    test "renders form for editing chosen lobby", %{conn: conn, lobby: lobby} do
      conn = get(conn, Routes.lobby_path(conn, :edit, lobby))
      assert html_response(conn, 200) =~ "Edit Lobby"
    end
  end

  describe "update lobby" do
    setup [:create_lobby]

    test "redirects when data is valid", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.lobby_path(conn, :update, lobby), lobby: @update_attrs)
      assert redirected_to(conn) == Routes.lobby_path(conn, :show, lobby)

      conn = get(conn, Routes.lobby_path(conn, :show, lobby))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.lobby_path(conn, :update, lobby), lobby: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Lobby"
    end
  end

  describe "delete lobby" do
    setup [:create_lobby]

    test "deletes chosen lobby", %{conn: conn, lobby: lobby} do
      conn = delete(conn, Routes.lobby_path(conn, :delete, lobby))
      assert redirected_to(conn) == Routes.lobby_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.lobby_path(conn, :show, lobby))
      end
    end
  end

  defp create_lobby(_) do
    lobby = fixture(:lobby)
    %{lobby: lobby}
  end
end
