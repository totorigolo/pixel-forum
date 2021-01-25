defmodule PixelForumWeb.EnsureRolePlugTest do
  use PixelForumWeb.ConnCase, async: true

  alias PixelForumWeb.EnsureRolePlug

  @opts ~w(admin)a
  @user %{id: 1, role: "user"}
  @admin %{id: 2, role: "admin"}

  setup do
    conn =
      build_conn()
      |> Plug.Conn.put_private(:plug_session, %{})
      |> Plug.Conn.put_private(:plug_session_fetch, :done)
      |> Pow.Plug.put_config(otp_app: :pixel_forum)
      |> fetch_flash()

    {:ok, conn: conn}
  end

  test "call/2 with no user halts and redirects to index", %{conn: conn} do
    opts = EnsureRolePlug.init(@opts)
    conn = EnsureRolePlug.call(conn, opts)

    assert conn.halted
    assert Phoenix.ConnTest.redirected_to(conn) == Routes.page_path(conn, :index)
  end

  test "call/2 with non-admin user halts and redirects to index", %{conn: conn} do
    opts = EnsureRolePlug.init(@opts)
    conn =
      conn
      |> Pow.Plug.assign_current_user(@user, otp_app: :pixel_forum)
      |> EnsureRolePlug.call(opts)

    assert conn.halted
    assert Phoenix.ConnTest.redirected_to(conn) == Routes.page_path(conn, :index)
  end

  test "call/2 with non-admin user and multiple roles does not halt", %{conn: conn} do
    opts = EnsureRolePlug.init(~w(user admin)a)
    conn =
      conn
      |> Pow.Plug.assign_current_user(@user, otp_app: :pixel_forum)
      |> EnsureRolePlug.call(opts)

    refute conn.halted
  end

  test "call/2 with admin user does not halt", %{conn: conn} do
    opts = EnsureRolePlug.init(@opts)
    conn =
      conn
      |> Pow.Plug.assign_current_user(@admin, otp_app: :pixel_forum)
      |> EnsureRolePlug.call(opts)

    refute conn.halted
  end
end
