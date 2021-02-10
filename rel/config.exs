# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
    # This sets the default release built by `mix distillery.release`
    default_release: :default,
    # This sets the default environment used by `mix distillery.release`
    # default_environment: config_env()
    default_environment: :prod

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"Q=`6G0jixu83x/X9Wknm7%}^)s$/SJ=3ce=;Ms.YIg{=0sjJ2/Q[p[o{Sx0l_/x6"
  set vm_args: "rel/vm.args"
  set pre_configure_hooks: "rel/hooks/pre_configure.d"
  set post_start_hooks: "rel/hooks/post_start.d"

  # There are two different kind of configuration: config/ and rel/config/. The
  # first one is handled by Mix when run locally, or is compiled into Distillery
  # releases, forbidding the use of secrets there and preventing using runtime
  # configuration such as environment variables. Files in rel/config/ are copied
  # as-is using the overlays rule below, so they are not secure, but allow using
  # environment variables. To handle secrets config, we use Docker secrets.
  set overlays: [
    {:copy, "rel/config/config.exs", "etc/config.exs"}
  ]
  set config_providers: [
    {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]},
    {Distillery.Releases.Config.Providers.Elixir, ["/run/secrets/pixel-forum-joken-config.exs"]},
    {Distillery.Releases.Config.Providers.Elixir, ["/run/secrets/pixel-forum-phoenix-config.exs"]},
    {Distillery.Releases.Config.Providers.Elixir, ["/run/secrets/pixel-forum-postgres-config.exs"]},
    {Distillery.Releases.Config.Providers.Elixir, ["/run/secrets/pixel-forum-pow_assent-config.exs"]},
  ]
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix distillery.release`, the first release in the file
# will be used by default

release :pixel_forum do
  set version: current_version(:pixel_forum)
  set applications: [
    :runtime_tools
  ]
end
