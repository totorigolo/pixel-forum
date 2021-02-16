defmodule PixelForum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # Start the Ecto repository
      PixelForum.Repo,
      # Start the Telemetry supervisor
      PixelForumWeb.Telemetry,
      # Start the cluster supervisor for node discovery
      {Cluster.Supervisor, [topologies, [name: PixelForum.ClusterSupervisor]]},
      # Start the PubSub system
      {Phoenix.PubSub, name: PixelForum.PubSub},
      # Start the presence module (must be after PubSub and before the endpoint)
      PixelForumWeb.Presence,
      # Start the forum supervisor
      PixelForum.Forum.Supervisor,
      # Start the Endpoint (http/https)
      PixelForumWeb.Endpoint,

      # Start a worker by calling: PixelForum.Worker.start_link(arg)
      # {PixelForum.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PixelForum.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PixelForumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
