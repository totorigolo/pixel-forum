defmodule PixelForumWeb.ImageChannel do
  use PixelForumWeb, :channel
  alias PixelForumWeb.Presence
  alias PixelForum.Users.User

  @impl true
  def join("image:lobby", _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def join("image:" <> _any, _params, _socket) do
    raise "not implemented"
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.unique_id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:pixel_changed, {{x, y}, {r, g, b}}}, socket) do
    push(socket, "pc", %{d: [x, y, r, g, b]})
    {:noreply, socket}
  end

  @impl true
  def handle_in("change_pixel", %{"x" => x, "y" => y, "r" => r, "g" => g, "b" => b}, socket) do
    with {:ok, user_id} <- get_user_id(socket),
         coordinate = {String.to_integer(x), String.to_integer(y)},
         color = {String.to_integer(r), String.to_integer(g), String.to_integer(b)},
         :ok <- PixelForum.Images.Image.change_pixel(user_id, coordinate, color) do
      {:reply, :ok, socket}
    else
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  # defp connected?(%{assigns: %{current_user: %User{}}}), do: true
  # defp connected?(_socket), do: false

  defp get_user_id(%{assigns: %{current_user: %User{id: user_id}}}), do: {:ok, user_id}
  defp get_user_id(_socket), do: {:error, "not_logged_in"}
end
