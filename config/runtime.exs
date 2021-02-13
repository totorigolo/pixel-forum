import Config

config :pixel_forum, PixelForumWeb.Endpoint,
  http: [:inet6, port: System.fetch_env!("PORT")],
  url: [scheme: "https", port: 443, host: System.fetch_env!("DOMAIN")]

config :pixel_forum, PixelForum.Repo,
  database: System.fetch_env!("POSTGRES_DB"),
  hostname: System.fetch_env!("POSTGRES_HOST"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))
