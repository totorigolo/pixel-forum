defmodule PixelForum.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  use Pow.Ecto.Schema
  use PowAssent.Ecto.Schema

  schema "users" do
    field :role, :string, null: false, default: "user"
    field :api_token_hash, :string

    pow_user_fields()
    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
  end

  @spec changeset_role(Ecto.Schema.t() | Changeset.t(), map()) :: Changeset.t()
  def changeset_role(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:role])
    |> validate_inclusion(:role, ~w(user admin))
  end

  @spec changeset_api_token(Ecto.Schema.t() | Changeset.t(), map()) :: Changeset.t()
  def changeset_api_token(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:api_token_hash])
    |> unique_constraint(:api_token_hash)
  end
end
