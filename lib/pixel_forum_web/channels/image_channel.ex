defmodule PixelForumWeb.ImageChannel do
  use PixelForumWeb, :channel
  alias PixelForumWeb.Presence

  @impl true
  def join("image:lobby", _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def join("image:" <> _any, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
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
  def handle_in("increment", %{"value" => value}, socket) do
    value = String.to_integer(value)
    increment_counter(value, socket)

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    false
  end

  defp increment_counter(amount, socket) when is_integer(amount) do
    if 0 < amount and amount < 100 do
      new_value = PixelForum.Image.increment(amount)
      broadcast!(socket, "new_value", %{value: new_value})
    end
  end
end
