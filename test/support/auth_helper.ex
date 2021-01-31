defmodule PixelForumWeb.Test.AuthHelper do
  @otp_app :pixel_forum
  @default_user %PixelForum.Users.User{id: 0, email: "user@example.com"}

  @doc """
  Logs as a user, properly putting the user inside the conn assigns as well as
  into Pow's credentials cache. Works for both classical controllers and
  LiveViews. If there is a :user in the test context, it will be used instead of
  the default one.
  """
  def log_as_user(%{conn: conn} = params) do
    user = Map.get(params, :user, @default_user)

    conn =
      conn
      |> put_user_in_session(user)
      |> assign_current_user(user)

    {:ok, conn: conn, user: user}
  end

  defp sign_token(token) do
    salt = Atom.to_string(Pow.Plug.Session)
    secret_key_base = Application.get_env(@otp_app, PixelForumWeb.Endpoint)[:secret_key_base]

    crypt_conn =
      struct!(Plug.Conn, secret_key_base: secret_key_base)
      |> Pow.Plug.put_config(otp_app: @otp_app)

    Pow.Plug.sign_token(crypt_conn, salt, token)
  end

  defp session_token_key(), do: Pow.Plug.prepend_with_namespace([otp_app: @otp_app], "auth")

  defp put_user_in_credentials_cache(token, user) do
    cache_store_backend = Pow.Config.get([], :cache_store_backend, Pow.Store.Backend.EtsCache)
    Pow.Store.CredentialsCache.put([backend: cache_store_backend], token, {user, []})
  end

  defp put_user_in_session(conn, user) do
    token = "test-token-#{Pow.UUID.generate()}"
    signed_token = sign_token(token)

    put_user_in_credentials_cache(token, user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(session_token_key(), signed_token)
    |> Plug.Conn.put_session(session_token_key() <> "_unsigned", token)
  end

  defp assign_current_user(conn, user) do
    conn
    |> Pow.Plug.put_config(otp_app: @otp_app)
    |> Pow.Plug.assign_current_user(user, [])
  end
end
