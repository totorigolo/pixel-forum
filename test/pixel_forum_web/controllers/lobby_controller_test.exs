defmodule PixelForumWeb.LobbyControllerTest do
  use PixelForumWeb.ConnCase,
    # Those tests cannot be async because some of them start new processes.
    async: false

  alias PixelForum.Lobbies.Lobby

  use PixelForum.Fixtures, [:lobby]

  setup [:log_as_admin]

  describe "get_image" do
    setup [:create_lobby]

    test "returns a PNG", %{conn: conn, lobby: lobby} do
      conn = get(conn, Routes.lobby_path(conn, :get_image, lobby))
      assert response_content_type(conn, :png) =~ "image/png"
      <<"\x89PNG\r\n", _::binary>> = response(conn, 200)
    end

    test "returns an error when the lobby is not found", %{conn: conn} do
      conn = get(conn, Routes.lobby_path(conn, :get_image, %Lobby{id: "invalid"}))
      assert json_response(conn, 404) == %{"message" => "Lobby not found: invalid."}
    end
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
    test "redirects to show when data is valid", %{conn: authed_conn} do
      conn = post(authed_conn, Routes.lobby_path(authed_conn, :create), lobby: create_attrs(:lobby))

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.lobby_path(conn, :show, id)

      conn = get(authed_conn, Routes.lobby_path(authed_conn, :show, id))
      assert html_response(conn, 200) =~ "Show Lobby"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.lobby_path(conn, :create), lobby: invalid_attrs(:lobby))
      assert html_response(conn, 200) =~ "New Lobby"
    end
  end

  describe "show lobby" do
    setup [:create_lobby]

    test "renders lobby information", %{conn: conn, lobby: lobby} do
      conn = get(conn, Routes.lobby_path(conn, :show, lobby))
      html = html_response(conn, 200)

      assert html =~ "Show Lobby"
      assert html =~ "<strong>UUID:</strong> #{lobby.id}"
      assert html =~ "<strong>Name:</strong> #{lobby.name}"
    end

    test "renders 404 error when invalid id", %{conn: conn} do
      lobby = %Lobby{id: Ecto.UUID.generate()}
      error = catch_error(get(conn, Routes.lobby_path(conn, :show, lobby)))
      assert 404 == Plug.Exception.status(error)
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
        put(authed_conn, Routes.lobby_path(authed_conn, :update, lobby), lobby: update_attrs(:lobby))

      assert redirected_to(conn) == Routes.lobby_path(conn, :show, lobby)

      conn = get(authed_conn, Routes.lobby_path(authed_conn, :show, lobby))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, lobby: lobby} do
      conn = put(conn, Routes.lobby_path(conn, :update, lobby), lobby: invalid_attrs(:lobby))
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

  describe "reset image" do
    setup [:create_lobby]

    test "redirects when lobby exists", %{conn: authed_conn, lobby: lobby} do
      conn = get(authed_conn, Routes.lobby_path(authed_conn, :reset_image, lobby))
      assert redirected_to(conn) == Routes.lobby_path(conn, :show, lobby)
      assert get_flash(conn, :info) =~ "Lobby image reset successfully"
    end

    test "renders 404 error when invalid id", %{conn: conn} do
      lobby = %Lobby{id: Ecto.UUID.generate()}
      error = catch_error(get(conn, Routes.lobby_path(conn, :reset_image, lobby)))
      assert 404 == Plug.Exception.status(error)
    end
  end

  defp create_lobby(_) do
    lobby = lobby_fixture()
    %{lobby: lobby}
  end

  defp log_as_admin(%{conn: conn}) do
    admin = %PixelForum.Users.User{email: "admin@example.com", role: "admin"}
    conn = Pow.Plug.assign_current_user(conn, admin, otp_app: :pixel_forum)
    {:ok, conn: conn}
  end
end
