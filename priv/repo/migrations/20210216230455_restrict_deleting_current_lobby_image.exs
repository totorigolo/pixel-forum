defmodule PixelForum.Repo.Migrations.RestrictDeletingCurrentLobbyImage do
  use Ecto.Migration

  def change do
    execute """
        ALTER TABLE lobbies
          DROP CONSTRAINT lobbies_image_version_fkey,
          ADD CONSTRAINT lobbies_image_version_fkey
            FOREIGN KEY (image_version, id)
            REFERENCES images(version, lobby_id)
            ON DELETE RESTRICT;
      """, """
        ALTER TABLE lobbies
          DROP CONSTRAINT lobbies_image_version_fkey,
          ADD CONSTRAINT lobbies_image_version_fkey
            FOREIGN KEY (image_version, id)
            REFERENCES images(version, lobby_id);
      """
  end
end
