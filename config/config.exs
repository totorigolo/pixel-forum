# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pixel_forum,
  ecto_repos: [PixelForum.Repo]

# Configures the endpoint
config :pixel_forum, PixelForumWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PixelForumWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PixelForum.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:file, :line, :pid, :crash_reason, :request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Pow configuration
config :pixel_forum, :pow,
  user: PixelForum.Users.User,
  repo: PixelForum.Repo,
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  routes_backend: PixelForumWeb.Pow.Routes,
  messages_backend: PixelForumWeb.Pow.Messages

# Use Mint to support HTTP/2
config :pixel_forum, :pow_assent,
  http_adapter: Assent.HTTPAdapter.Mint

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
