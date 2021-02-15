defmodule PixelForum.Lobbies.Lobby do
  use Ecto.Schema
  import Ecto.Changeset

  alias PixelForum.Images.Image

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "lobbies" do
    field :name, :string
    field :id_creator_user, :binary_id

    field :image_version, :integer
    has_many :images, Image

    # Composite foreign keys are not supported in Ecto, so this must be
    # implemented manually in the context.
    # has_one :last_image, Image,
    #   foreign_key: [:lobby_id, :version],
    #   references: [:id, :image_version]

    timestamps()
  end

  @doc false
  def changeset(lobby, attrs) do
    lobby
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name], message: "already exists")
  end

  @doc false
  def change_version_changeset(lobby, new_image_version) do
    lobby
    |> optimistic_lock(:image_version, fn _ -> new_image_version end)
    |> change(image_version: new_image_version)
  end
end
