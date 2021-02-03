defmodule PixelForum.Users do
  alias PixelForum.{Repo, Users.User}

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

  @spec create_api_token(t()) :: {:ok, t(), String.t()}
  def create_api_token(user) do
    with token = generate_token(),
         hashed_token = hash_token(token),
         {:ok, user} <-
           user
           |> User.changeset_api_token(%{api_token_hash: hashed_token})
           |> Repo.update() do
      {:ok, user, token}
    else
      _any -> create_api_token(user)
    end
  end

  @spec revoke_api_token(t()) :: {:ok, t()}
  def revoke_api_token(user) do
    user
    |> User.changeset_api_token(%{api_token_hash: nil})
    |> Repo.update()
  end

  @spec verify_api_token(t(), String.t()) :: :ok | :error
  def verify_api_token(user, api_token) do
    cond do
      is_nil(api_token) -> :error
      is_nil(user.api_token_hash) -> :error
      hash_token(api_token) == user.api_token_hash -> :ok
      true -> :error
    end
  end

  # Generates a 256-bit random string.
  defp generate_token() do
    raw = Ecto.UUID.generate() <> Ecto.UUID.generate()
    :crypto.hash(:sha256, raw) |> Base.encode16() |> String.downcase()
  end

  defp hash_token(token), do: :crypto.hash(:sha256, token) |> Base.encode16() |> String.downcase()
end
