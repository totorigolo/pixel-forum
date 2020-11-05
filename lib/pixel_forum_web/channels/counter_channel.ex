defmodule PixelForumWeb.CounterChannel do
  use PixelForumWeb, :channel

  @impl true
  def join("counter:lobby", _params, socket) do
    {:ok, socket}
  end

  @impl true
  def join("counter:" <> _any, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("increment", %{"value" => value}, socket) do
    value = String.to_integer(value)
    new_value = PixelForum.Counter.increment(value)

    broadcast!(socket, "new_value", %{value: new_value})

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    false
  end
end
