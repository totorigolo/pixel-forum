defmodule PixelForumWeb.Live.AuthHelperTest do
  use PixelForumWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import PixelForumWeb.Test.AuthHelper

  # TODO: Ideally, we should use a LiveView made only for testing, instead of a
  # real page.

  describe "when not logged in" do
    test "redirects to the index", %{conn: conn} do
      index_path = Routes.page_path(conn, :index)

      assert {:error, {:redirect, %{to: ^index_path}}} =
               live(conn, Routes.profile_path(conn, :index))
    end
  end

  describe "when logged in" do
    setup [:log_as_user]

    test "shows current user info", %{conn: authed_conn, user: user} do
      {:ok, page_live, disconnected_html} =
        live(authed_conn, Routes.profile_path(authed_conn, :index))

      assert disconnected_html =~ user.email
      assert render(page_live) =~ user.email
    end

    test "properly redirects when session expires", %{conn: authed_conn, user: user} do
      {:ok, page_live, _disconnected_html} =
        live(authed_conn, Routes.profile_path(authed_conn, :index))

      assert render(page_live) =~ user.email

      expire_user_session(authed_conn)
      assert_redirect(page_live, "/", 200)
    end
  end

  defp expire_user_session(conn) do
    token = Plug.Conn.get_session(conn, session_token_key() <> "_unsigned")
    cache_store_backend = Pow.Config.get([], :cache_store_backend, Pow.Store.Backend.EtsCache)
    Pow.Store.CredentialsCache.delete([backend: cache_store_backend], token)
  end

  defp session_token_key(), do: Pow.Plug.prepend_with_namespace([otp_app: :pixel_forum], "auth")
end
