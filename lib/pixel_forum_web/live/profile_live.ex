defmodule PixelForumWeb.Live.ProfileLive do
  use PixelForumWeb, :live_view

  use PixelForumWeb.Live.AuthHelper, otp_app: :pixel_forum

  @impl true
  def mount(_params, session, socket) do
    socket = assign_current_user!(socket, session)

    {:ok, socket}
  end

  @impl true
  def session_expired(socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Session expired.")
     |> push_redirect(to: Routes.page_path(socket, :index))}
  end
end
