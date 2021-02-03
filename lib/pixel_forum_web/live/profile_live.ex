defmodule PixelForumWeb.Live.ProfileLive do
  use PixelForumWeb, :live_view
  use PixelForumWeb.Live.AuthHelper, otp_app: :pixel_forum

  alias PixelForum.Users

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign_current_user!(session)
     |> assign(api_token: nil)
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
  def handle_event("create_api_token", _value, socket) do
    # Keep in mind that this does not update the cached user in Pow's store nor
    # changes the user session, which is impossible to do from a LiveView.
    # Hence, `current_user.api_token_hash` should never be used.
    {:ok, user, api_token} = Users.create_api_token(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(api_token: api_token)
     |> assign(current_user: user)
     |> put_flash(:info, "New API token created.")}
  end

  @impl true
  def handle_event("revoke_api_token", _value, socket) do
    {:ok, user} = Users.revoke_api_token(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(api_token: nil)
     |> assign(current_user: user)
     |> put_flash(:info, "The API token has been revoked.")}
  end
end
