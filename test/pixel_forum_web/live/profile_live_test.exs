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

    test "shows user email", %{conn: conn, user: user} do
      {:ok, view, html} = live(conn, Routes.profile_path(conn, :index))

      assert html =~ "<h1>Profile</h1>"
      assert html =~ "<strong>User email:</strong> #{user.email}"

      rendered = render(view)
      assert rendered =~ "<h1>Profile</h1>"
      assert rendered =~ "<strong>User email:</strong> #{user.email}"
    end
  end

  describe "api_token" do
    setup [:log_as_user]

    test "can create API token", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))

      assert view
             |> element("button", "Create a new token")
             |> render_click() =~ "This is your new private API token"
    end

    test "API token shown only when created", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))

      new_token_msg = "This is your new private API token"
      refute render(view) =~ new_token_msg

      assert view
             |> element("button", "Create")
             |> render_click() =~ new_token_msg

      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))
      refute render(view) =~ new_token_msg
    end
  end
end
