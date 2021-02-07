defmodule PixelForumWeb.Live.ProfileLive do
  use PixelForumWeb, :live_view
  use PixelForumWeb.Live.AuthHelper, otp_app: :pixel_forum

  alias PixelForum.Users

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign_current_user!(session)
     |> assign(token: nil)
     |> refresh_user!()}
  end

  @impl true
  def session_expired(socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Session expired.")
     |> push_redirect(to: Routes.page_path(socket, :index))}
  end

  @impl true
  def handle_event("create_token", _value, socket) do
    {:ok, token} = Users.create_access_token(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(token: token)
     |> put_flash(:info, "New API token created.")}
  end
end
