defmodule PixelForumWeb.Pow.Routes do
  use Pow.Phoenix.Routes
  alias PixelForumWeb.Router.Helpers, as: Routes

  @impl true
  def after_sign_out_path(conn), do: Routes.page_path(conn, :index)

  @impl true
  def user_not_authenticated_path(conn), do: Routes.page_path(conn, :index)
end
