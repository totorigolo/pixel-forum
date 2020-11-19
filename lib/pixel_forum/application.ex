defmodule PixelForum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      PixelForum.Repo,
      # Start the Telemetry supervisor
      PixelForumWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PixelForum.PubSub},
      # Start the Endpoint (http/https)
      PixelForumWeb.Endpoint,
      # Start the presence module
      PixelForumWeb.Presence,
      # Start the forum supervisor and lobby spawner sub-supervision tree
      %{
        id: PixelForum.Forum.Supervisor,
        start: {Supervisor, :start_link, [
          [
            # Start the forum supervisor
            PixelForum.Lobbies.ForumSupervisor,
            # Start the lobby spawner
            PixelForum.Lobbies.LobbySpawner
          ],
          [strategy: :one_for_all, name: PixelForum.Forum.Supervisor]
        ]},
        type: :supervisor
      },

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
