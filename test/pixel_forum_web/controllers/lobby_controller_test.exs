defmodule PixelForumWeb.LobbyControllerTest do
  use PixelForumWeb.ConnCase, async: true

  alias PixelForum.Lobbies

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup [:log_as_admin]

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
    test "redirects to show when data is valid", %{conn: authed_conn} do
      conn = post(authed_conn, Routes.lobby_path(authed_conn, :create), lobby: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.lobby_path(conn, :show, id)

      conn = get(authed_conn, Routes.lobby_path(authed_conn, :show, id))
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

    test "redirects when data is valid", %{conn: authed_conn, lobby: lobby} do
      conn =
        put(authed_conn, Routes.lobby_path(authed_conn, :update, lobby), lobby: @update_attrs)

      assert redirected_to(conn) == Routes.lobby_path(conn, :show, lobby)

      conn = get(authed_conn, Routes.lobby_path(authed_conn, :show, lobby))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.lobby_path(conn, :update, lobby), lobby: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Lobby"
    end
  end

  describe "delete lobby" do
    setup [:create_lobby]

    test "deletes chosen lobby", %{conn: authed_conn, lobby: lobby} do
      conn = delete(authed_conn, Routes.lobby_path(authed_conn, :delete, lobby))
      assert redirected_to(conn) == Routes.lobby_path(conn, :index)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.lobby_path(authed_conn, :show, lobby))
      end
    end
  end

  defp create_lobby(_) do
    lobby = fixture(:lobby)
    %{lobby: lobby}
  end

  defp log_as_admin(%{conn: conn}) do
    admin = %PixelForum.Users.User{email: "admin@example.com", role: "admin"}
    conn = Pow.Plug.assign_current_user(conn, admin, otp_app: :pixel_forum)
    {:ok, conn: conn}
  end

  def fixture(:lobby) do
    {:ok, lobby} = Lobbies.create_lobby(@create_attrs)
    lobby
  end
end
