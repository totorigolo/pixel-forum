defmodule PixelForumWeb.API.JwtPlug do
  @moduledoc """
  Extracts the claims from the bearer token and puts them inside the conn's
  assigns under :claims. If no bearer token in passed into the headers, nil will
  be stored instead of the claim map. However, if the token is invalid, the conn
  will be halted and an appropriate error will be returned.
  """
  @behaviour Plug

  alias PixelForum.Users

  @impl true
  @callback init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @impl true
  @callback call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    with {:ok, jwt} <- fetch_bearer_token(conn),
         {:ok, claims} <- Users.verify_access_token(jwt) do
      Plug.Conn.assign(conn, :claims, claims)
    else
      {:error, :no_bearer} ->
        Plug.Conn.assign(conn, :claims, nil)

      {:error, :signature_error} ->
        halt_401(conn, "Invalid token.")

      {:error, :empty_signer} ->
        raise "Cannot verify JWT token: empty signer. Check the Joken configuration."

      {:error, joken_reason} when is_list(joken_reason) ->
        case Keyword.fetch!(joken_reason, :claim) do
          "exp" -> halt_401(conn, "Token expired.")
          _ -> halt_401(conn, "Invalid token.")
        end
    end
  end

  defp fetch_bearer_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> bearer | _rest] -> {:ok, bearer}
      _any -> {:error, :no_bearer}
    end
  end

  defp halt_401(conn, message) do
    conn
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.json(%{error: %{code: 401, message: message}})
    |> Plug.Conn.halt()
  end
end
