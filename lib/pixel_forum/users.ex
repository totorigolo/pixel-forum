defmodule PixelForum.Users do
  alias PixelForum.Repo
  alias PixelForum.Users.{Token, User}

  @type t :: %User{}

  @spec create_admin(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create_admin(params) do
    %User{}
    |> User.changeset(params)
    |> User.changeset_role(%{role: "admin"})
    |> Repo.insert()
  end

  @spec set_admin_role(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def set_admin_role(user) do
    user
    |> User.changeset_role(%{role: "admin"})
    |> Repo.update()
  end

  @spec is_admin?(t()) :: boolean()
  def is_admin?(%{role: "admin"}), do: true
  def is_admin?(_any), do: false

  @spec create_access_token(t()) :: {:ok, Joken.bearer_token()}
  def create_access_token(user) do
    {:ok, generate_access_token!(user)}
  end

  @spec verify_access_token(Joken.bearer_token()) ::
          {:ok, map()} | {:error, :signature_error | Joken.error_reason()}
  def verify_access_token(jwt), do: Token.verify_and_validate(jwt)

  @spec generate_access_token!(t()) :: Joken.bearer_token()
  defp generate_access_token!(user) do
    {:ok, token, _claims} = Token.generate_and_sign(%{"sub" => user.id, "role" => user.role})
    token
  end
end
