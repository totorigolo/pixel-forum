defmodule PixelForum.Repo.Migrations.CreateLobbies do
  use Ecto.Migration

  def change do
    create table(:lobbies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :id_creator_user, references(:users, on_delete: :restrict, type: :id)

      timestamps()
    end

    create index(:lobbies, [:id_creator_user])
  end
end
