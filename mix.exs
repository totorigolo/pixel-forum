defmodule PixelForum.MixProject do
  use Mix.Project

  def project do
    [
      app: :pixel_forum,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext, :rustler] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      rustler_crates: rustler_crates(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PixelForum.Application, []},
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:test), do: [:logger, :runtime_tools, :mnesia]
  defp extra_applications(_), do: [:logger, :runtime_tools, :mnesia, :os_mon]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_psql_extras, "~> 0.2"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_view, "~> 0.14.6"},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:rustler, "~> 0.21.1"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:msgpax, "~> 2.2"},
      {:pow, "~> 1.0.21"},
      {:pow_assent, "~> 0.4.9"},
      {:mint, "~> 1.2"}, # Required to support HTTP/2 in Pow Assent
      {:castore, "~> 0.1.8"}, # Required for SSL validation in Pow Assent
    ]
  end

  defp rustler_crates do
    [mutableimage: [
      path: "native/mutableimage-rs",
      mode: rustc_mode(Mix.env)
    ]]
  end

  # defp rustc_mode(:prod), do: :release
  # defp rustc_mode(_), do: :debug
  defp rustc_mode(_), do: :release

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
