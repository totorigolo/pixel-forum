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

  scope "/", PixelForumWeb do
    pipe_through [:browser, :protected]

    # TODO: Protect this with roles
    # resources "/lobbies", LobbyController
  end

  # scope "/api", PixelForumWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/admin" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PixelForumWeb.Telemetry
    end
  end
end
