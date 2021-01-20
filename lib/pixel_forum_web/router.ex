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
  end

  pipeline :unsafe_minimal_skip_csrf_protection do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :admin do
    plug PixelForumWeb.EnsureRolePlug, :admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    # pow_routes() -> Using only Pow Assent for sessions
    pow_session_routes()

    pow_assent_routes()
  end

  scope "/" do
    pipe_through :unsafe_minimal_skip_csrf_protection
    pow_assent_authorization_post_callback_routes()
  end

  scope "/", PixelForumWeb do
    pipe_through :browser

    live "/", PageLive, :index

    get "/lobby/:lobby/image", LobbyController, :get_image
  end

  # scope "/api", PixelForumWeb do
  #   pipe_through :api
  # end

  scope "/admin", PixelForumWeb do
    pipe_through [:browser, :protected, :admin]

    get "/", AdminController, :index
    resources "/lobbies", LobbyController

    import Phoenix.LiveDashboard.Router
    live_dashboard "/dashboard", metrics: PixelForumWeb.Telemetry
  end
end
