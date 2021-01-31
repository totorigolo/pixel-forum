defmodule PixelForumWeb.Live.ProfileLiveTest do
  use PixelForumWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import PixelForumWeb.Test.AuthHelper

  describe "when not logged in" do
    test "redirects to the index", %{conn: conn} do
      index_path = Routes.page_path(conn, :index)

      assert {:error, {:redirect, %{to: ^index_path}}} =
               live(conn, Routes.profile_path(conn, :index))
    end
  end

  describe "when logged in" do
    setup [:log_as_user]

    test "shows user email", %{conn: authed_conn, user: user} do
      {:ok, page_live, disconnected_html} = live(authed_conn, Routes.profile_path(authed_conn, :index))

      assert disconnected_html =~ "<h1>Profile</h1>"
      assert disconnected_html =~ "<strong>User email:</strong> #{user.email}"

      rendered = render(page_live)
      assert rendered =~ "<h1>Profile</h1>"
      assert rendered =~ "<strong>User email:</strong> #{user.email}"
    end
  end
end
