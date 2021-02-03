defmodule PixelForum.Repo.Migrations.AddUserApiToken do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :api_token_hash, :string
    end

    create unique_index(:users, [:api_token_hash])
  end
end
