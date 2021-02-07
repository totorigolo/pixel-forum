defmodule PixelForumWeb.API.AuthHelpers do
  @moduledoc false

  @spec get_claims(Plug.Conn.t()) :: map() | nil
  def get_claims(%{assigns: %{claims: nil}}), do: nil
  def get_claims(%{assigns: %{claims: claims}}), do: claims
  def get_claims(_conn), do: raise("No claims in conn, check that JwtPlug is used.")

  @spec get_claims!(Plug.Conn.t()) :: map()
  def get_claims!(conn) do
    claims = get_claims(conn)

    if is_nil(claims),
      do: raise("No claims in conn. Please protect this route with RequireAuthenticatedPlug.")

    claims
  end
end
