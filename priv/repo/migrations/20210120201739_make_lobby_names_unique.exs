defmodule PixelForum.Repo.Migrations.MakeLobbyNamesUnique do
  use Ecto.Migration

  def change do
    create unique_index(:lobbies, [:name])
  end
end
