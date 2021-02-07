defmodule PixelForum.Repo.Migrations.RemoveUserApiToken do
  use Ecto.Migration

  def change do
    drop unique_index(:users, [:api_token_hash])

    alter table("users") do
      remove :api_token_hash, :string, default: nil
    end
  end
end
