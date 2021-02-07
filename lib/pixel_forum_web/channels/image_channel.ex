defmodule PixelForumWeb.ImageChannel do
  use PixelForumWeb, :channel
  alias PixelForumWeb.Presence

  @impl true
  def join("image:" <> lobby_id, _params, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, lobby_id: lobby_id)}
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
  def handle_info({:pixel_changed, _}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:new_change_batch, change_batch}, socket) do
    push(socket, "pixel_batch", %{d: Msgpax.Bin.new(change_batch)})
    {:noreply, socket}
  end

  @impl true
  def handle_info(:image_reset, socket) do
    push(socket, "image_reset", %{})
    {:noreply, socket}
  end
end
