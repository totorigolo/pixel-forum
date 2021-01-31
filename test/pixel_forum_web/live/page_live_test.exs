defmodule PixelForumWeb.Live.PageLiveTest do
  use PixelForumWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "not logged in" do
    test "disconnected and connected render", %{conn: conn} do
      {:ok, page_live, disconnected_html} = live(conn, "/")
      assert disconnected_html =~ "<h1>Lobbies</h1>"
      assert render(page_live) =~ "<h1>Lobbies</h1>"
    end
  end
end
