defmodule PixelForumWeb.PageControllerTest do
  use PixelForumWeb.ConnCase, async: true

  describe "keep_alive" do
    test "Returns an ok response", %{conn: conn} do
      conn = get(conn, Routes.page_path(conn, :keep_alive))
      assert text_response(conn, 200) == "ok"
    end
  end
end
