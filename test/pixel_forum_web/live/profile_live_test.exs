defmodule PixelForumWeb.Live.ProfileLiveTest do
  use PixelForumWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import PixelForumWeb.Test.AuthHelper

  alias PixelForum.Users

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

    test "can create API token if has none", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))

      assert render(view) =~ "No token"

      assert view
             |> element("button", "Create a new token")
             |> render_click() =~ "This is your new API token"
    end

    test "cannot create API token if already has one", %{conn: conn, user: user} do
      {:ok, _user, _api_token} = Users.create_api_token(user)
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))
      refute render(view) =~ "Create a new token"
    end

    test "API token shown only when created", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))

      refute render(view) =~ "This is your new API token"

      assert view
             |> element("button", "Create")
             |> render_click() =~ "This is your new API token"

      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))
      refute render(view) =~ "This is your new API token"
    end

    test "can revoke API token if has one", %{conn: conn, user: user} do
      {:ok, _user, _api_token} = Users.create_api_token(user)
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))

      assert render(view) =~ "You currently have an API token"

      assert view
             |> element("button", "Revoke the token")
             |> render_click() =~ "No token"
    end

    test "cannot revoke API token if has none", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.profile_path(conn, :index))
      refute render(view) =~ "Revoke the token"
    end
  end
end
