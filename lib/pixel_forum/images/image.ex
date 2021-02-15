defmodule PixelForum.Images.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias PixelForum.Lobbies.Lobby

  @primary_key false
  @foreign_key_type :binary_id
  schema "images" do
    belongs_to :lobby, Lobby, primary_key: true
    field :version, :integer, primary_key: true

    field :date, :naive_datetime

    field :png_blob, :binary

    timestamps()
  end

  @doc false
  def new_image_changeset(lobby_id, attrs) do
    %__MODULE__{}
    |> cast(attrs, [:version, :date, :png_blob])
    |> put_change(:lobby_id, lobby_id)
    |> validate_required([:version, :date, :png_blob])
    |> validate_change(:png_blob, fn :png_blob, blob ->
      if not is_png(blob), do: [png_blob: "not a valid PNG blob"], else: []
    end)
    |> unique_constraint(:version, name: :images_pkey, message: "already exists")
  end

  defp is_png(<<0x89, "PNG", "\r\n", 0x1A, "\n", _::binary>>), do: true
  defp is_png(_blob), do: false
end
