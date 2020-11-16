defmodule PixelForum.Lobbies.Lobby do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lobbies" do
    field :name, :string
    field :id_creator_user, :binary_id

    timestamps()
  end

  @doc false
  def changeset(lobby, attrs) do
    lobby
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
