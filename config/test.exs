import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :pixel_forum, PixelForum.Repo,
  username: "postgres",
  password: "postgres",
  database: "pixel_forum_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pixel_forum, PixelForumWeb.Endpoint,
  secret_key_base: "test-secret-key-base-that-needs-to-be-at-the-very-least-64-bytes",
  live_view: [signing_salt: "test-LiveView-salt"],
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Reduce the number of iterations to hash passwords to speed-up tests.
config :pow, Pow.Ecto.Schema.Password, iterations: 5

# Simple hard-coded key for tests.
config :joken,
  current_time_adapter: PixelForum.Test.JokenTimeMock,
  default_signer: [
    signer_alg: "HS256",
    key_octet: "key-for-tests"
  ]
