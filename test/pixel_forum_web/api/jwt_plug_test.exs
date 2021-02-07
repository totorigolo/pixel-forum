defmodule PixelForumWeb.API.JwtPlugTest do
  use PixelForumWeb.ConnCase, async: true
  use Plug.Test

  alias PixelForum.Repo
  alias PixelForum.Users
  alias PixelForum.Users.User

  alias PixelForumWeb.API.JwtPlug

  @opts JwtPlug.init([])

  setup do
    {:ok, _pid} = start_supervised(PixelForum.Test.JokenTimeMock)
    :ok
  end

  setup [:create_user, :create_jwt]

  test "assigns claims when token is valid", %{jwt: jwt} do
    conn =
      conn(:get, "/test")
      |> put_req_header("authorization", "Bearer " <> jwt)
      |> JwtPlug.call(@opts)

    assert %{"iss" => _, "aud" => _} = conn.assigns.claims
  end

  test "assigns nil as claims when there is no bearer token" do
    conn = conn(:get, "/test") |> JwtPlug.call(@opts)
    assert nil == conn.assigns.claims
  end

  test "halts with 401 when invalid token", %{jwt: jwt} do
    conn =
      conn(:get, "/test")
      |> put_req_header("authorization", "Bearer " <> jwt <> "?")
      |> JwtPlug.call(@opts)

    assert conn.status == 401
    assert conn.resp_body =~ "Invalid token"
  end

  test "halts with 401 when token is expired", %{jwt: jwt} do
    conn =
      conn(:get, "/test")
      |> put_req_header("authorization", "Bearer " <> jwt)

    two_days = 2 * 24 * 60 * 60
    PixelForum.Test.JokenTimeMock.advance(two_days)

    conn = JwtPlug.call(conn, @opts)

    assert conn.status == 401
    assert conn.resp_body =~ "Token expired"
  end

  test "halts with 401 when token is used too early", %{jwt: jwt} do
    conn =
      conn(:get, "/test")
      |> put_req_header("authorization", "Bearer " <> jwt)

    two_days = 2 * 24 * 60 * 60
    PixelForum.Test.JokenTimeMock.advance(-two_days)

    conn = JwtPlug.call(conn, @opts)

    assert conn.status == 401
    assert conn.resp_body =~ "Invalid token"
  end

  defp create_user(_) do
    valid_params = %{
      email: "test@example.com",
      password: "secret1234",
      password_confirmation: "secret1234"
    }

    {:ok, user} = Repo.insert(User.changeset(%User{}, valid_params))
    {:ok, user: user}
  end

  defp create_jwt(%{user: user}) do
    {:ok, token} = Users.create_access_token(user)
    {:ok, jwt: token}
  end
end
