# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :pixel_forum,
  ecto_repos: [PixelForum.Repo]

# Configures the endpoint
config :pixel_forum, PixelForumWeb.Endpoint,
  # url: [host: "localhost"],
  url: [scheme: "https", host: "dev.pixel-forum.busy.ovh", port: 443],
  secret_key_base: "B3hSYrhIVBLdM30U/RtI9yMU5Jl3N94sgJW1jjhyJzYblLJSagYjsmDmy/eIYzM5",
  render_errors: [view: PixelForumWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PixelForum.PubSub,
  live_view: [signing_salt: "2dekHauR"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :pixel_forum, :pow,
  user: PixelForum.Users.User,
  repo: PixelForum.Repo,
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  routes_backend: PixelForumWeb.Pow.Routes

config :pixel_forum, :pow_assent,
  http_adapter: Assent.HTTPAdapter.Mint,
  providers: [
    github: [
      client_id: "0383c210a6256b853672",
      client_secret: "7533c7a7283888a2065dd56edbaf4259426a1c6d",
      strategy: Assent.Strategy.Github
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
