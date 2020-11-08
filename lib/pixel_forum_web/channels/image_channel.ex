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
  def handle_in("change_pixel", %{"x" => x, "y" => y, "r" => r, "g" => g, "b" => b}, socket) do
    coordinate = {String.to_integer(x), String.to_integer(y)}
    color = {String.to_integer(r), String.to_integer(g), String.to_integer(b)}

    case PixelForum.Image.change_pixel(coordinate, color) do
      :ok ->
        broadcast!(socket, "pixel_changed", %{
          coordinate: coordinate |> Tuple.to_list(),
          color: color |> Tuple.to_list()
        })

        {:reply, :ok, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    false
  end
end
