defmodule PixelForumWeb.Router do
  use PixelForumWeb, :router

  use Pow.Phoenix.Router
  use PowAssent.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PixelForumWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Pow.Plug.Session, otp_app: :pixel_forum
  end

  pipeline :unsafe_minimal_skip_csrf_protection do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :browser_authenticated do
    plug Pow.Plug.RequireAuthenticated, error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :admin do
    plug PixelForumWeb.EnsureRolePlug, :admin
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PixelForumWeb.API.JwtPlug
  end

  pipeline :api_authenticated do
    plug PixelForumWeb.API.RequireAuthenticatedPlug
  end

  scope "/" do
    pipe_through :browser

    # Not using pow_routes() because we don't want registration using Pow, only
    # sessions.
    pow_session_routes()
    pow_assent_routes()

    # Call this to keep the session alive, which is essential in LiveViews.
    get "/keep-alive", PixelForumWeb.PageController, :keep_alive
  end

  scope "/" do
    pipe_through :unsafe_minimal_skip_csrf_protection
    pow_assent_authorization_post_callback_routes()
  end

  scope "/", PixelForumWeb do
    pipe_through :browser

    live "/", Live.PageLive, :index

    get "/lobby/:id/image", LobbyController, :get_image
  end

  scope "/", PixelForumWeb do
    pipe_through [:browser, :browser_authenticated]

    live "/profile", Live.ProfileLive, :index
  end

  scope "/admin", PixelForumWeb do
    pipe_through [:browser, :browser_authenticated, :admin]

    get "/", AdminController, :index
    resources "/lobbies", LobbyController
    get "/lobbies/:id/reset-image", LobbyController, :reset_image

    import Phoenix.LiveDashboard.Router
    live_dashboard "/dashboard", metrics: PixelForumWeb.Telemetry, ecto_repos: [PixelForum.Repo]
  end

  scope "/api", PixelForumWeb.API, as: :api do
    pipe_through :api

    get "/lobbies/:id/pixel/:x/:y", LobbyController, :get_pixel
  end

  scope "/api", PixelForumWeb.API, as: :api do
    pipe_through [:api, :api_authenticated]

    put "/lobbies/:id/pixel/:x/:y", LobbyController, :set_pixel
  end
end
