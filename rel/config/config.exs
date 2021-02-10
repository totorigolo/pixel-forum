import Config

config :logger, level: :info

config :pixel_forum, PixelForumWeb.Endpoint,
  http: [:inet6, port: System.fetch_env!("PORT")],
  url: [host: System.fetch_env!("DOMAIN"), port: System.fetch_env!("PORT")],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:pixel_forum, :vsn)

config :pixel_forum, PixelForum.Repo,
  database: System.fetch_env!("POSTGRES_DB"),
  hostname: "postgres", # This is the name of the Docker swarm service.
  adapter: Ecto.Adapters.Postgres,
  pool_size: String.to_integer(System.fetch_env!("POOL_SIZE") || "10")
