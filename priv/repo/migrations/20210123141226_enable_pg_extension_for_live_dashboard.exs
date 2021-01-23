defmodule PixelForum.Repo.Migrations.EnablePgExtensionForLiveDashboard do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION pg_stat_statements", "DROP EXTENSION pg_stat_statements"

    IO.puts("")
    IO.puts("#######################################################################################")
    IO.puts("")
    IO.puts("Note: Please read the following page to fully enable Ecto stats")
    IO.puts("      in Live Dashboard.")
    IO.puts("      https://www.postgresql.org/docs/current/pgstatstatements.html")
    IO.puts("")
    IO.puts("#######################################################################################")
    IO.puts("")
  end
end
