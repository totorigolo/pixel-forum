defmodule PixelForum.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  use PowAssent.Ecto.Schema

  schema "users" do
    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
  end
end
