defmodule PixelForumWeb.API.RequireAuthenticatedPlug do
  @moduledoc """
  Halts the connection and returns a 401 Not authenticated error if the claim
  map in the conn assigns is nil. See also PixelForumWeb.API.JwtPlug which puts
  the claims there.
  """
  @behaviour Plug

  @impl true
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @impl true
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(%{assigns: %{claims: nil}} = conn, _opts), do: halt_401(conn, "Not authenticated.")
  def call(conn, _opts), do: conn

  defp halt_401(conn, message) do
    conn
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.json(%{error: %{code: 401, message: message}})
    |> Plug.Conn.halt()
  end
end
