defmodule PixelForum.ReleaseTasks do
  def storage_up do
    PixelForum.Repo.__adapter__().storage_up(PixelForum.Repo.config())
  end

  def migrate do
    {:ok, _} = Application.ensure_all_started(:pixel_forum)

    path = Application.app_dir(:pixel_forum, "priv/repo/migrations")

    Ecto.Migrator.run(PixelForum.Repo, path, :up, all: true)
  end
end
