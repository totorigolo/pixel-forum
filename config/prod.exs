import Config

# Includes the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :pixel_forum, PixelForumWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:pixel_forum, :vsn)

# Do not print debug messages in production
config :logger, level: :info

config :pixel_forum, PixelForum.Repo,
  adapter: Ecto.Adapters.Postgres
