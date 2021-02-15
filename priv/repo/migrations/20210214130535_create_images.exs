defmodule PixelForum.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images, primary_key: false) do
      add :lobby_id,
          references(:lobbies, type: :binary_id, on_delete: :nothing),
          primary_key: true

      add :version, :integer, primary_key: true
      add :date, :naive_datetime

      add :png_blob, :binary

      timestamps()
    end

    create index(:images, [:lobby_id])
    create index(:images, [:lobby_id, :version])

    alter table(:lobbies) do
      add :image_version,
          references(:images, column: :version, on_delete: :nothing, with: [id: :lobby_id])
    end
  end
end
