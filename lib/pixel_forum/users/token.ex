defmodule PixelForum.Users.Token do
  use Joken.Config

  @impl true
  def token_config do
    default_claims(iss: "PixelForum", aud: "PixelForum API")
    |> add_claim("sub", nil, &is_valid_sub/1)
    |> add_claim("role", nil, &(&1 in ["admin", "user"]))
  end

  # sub is an integer user ID
  defp is_valid_sub(sub) when is_integer(sub), do: true
  defp is_valid_sub(_), do: false
end
