defmodule PixelForumWeb.API.AuthHelpersTest do
  use ExUnit.Case, async: true

  import PixelForumWeb.API.AuthHelpers

  describe "get_claims/1" do
    test "returns nil when the claims map is nil" do
      conn = struct!(Plug.Conn, assigns: %{claims: nil})
      assert nil == get_claims(conn)
    end

    test "returns the claims when the claims map is not nil" do
      claims = %{"sub" => 0, "exp" => "some time"}
      conn = struct!(Plug.Conn, assigns: %{claims: claims})
      assert claims == get_claims(conn)
    end

    test "raises when no claims in assigns" do
      conn = struct!(Plug.Conn, assigns: %{})
      exception = assert_raise RuntimeError, fn -> get_claims(conn) end
      assert Exception.message(exception) =~ "No claims in conn"
    end
  end

  describe "get_claims!/1" do
    test "returns the claims when the claims map is not nil" do
      claims = %{"sub" => 0, "exp" => "some time"}
      conn = struct!(Plug.Conn, assigns: %{claims: claims})
      assert claims == get_claims!(conn)
    end

    test "raises when the claims map is nil" do
      conn = struct!(Plug.Conn, assigns: %{claims: nil})
      exception = assert_raise RuntimeError, fn -> get_claims!(conn) end
      assert Exception.message(exception) =~ "No claims in conn"
    end
  end
end
