defmodule PixelForumWeb.ImageChannelTest do
  use PixelForumWeb.ChannelCase, async: true

  setup do
    {:ok, _, socket} =
      PixelForumWeb.MsgPackUserSocket
      |> socket("user_id", %{unique_id: 0})
      |> subscribe_and_join(PixelForumWeb.ImageChannel, "image:lobby-id")

    %{socket: socket}
  end

  describe "receiving :pixel_changed message" do
    test "does not trigger a push", %{socket: socket} do
      flush_messages()
      send(socket.channel_pid, {:pixel_changed, "anything"})
      refute_push _, _
    end

    test "does not trigger a broadcast", %{socket: socket} do
      flush_messages()
      send(socket.channel_pid, {:pixel_changed, "anything"})
      refute_broadcast _, _
    end
  end

  describe "receiving :new_change_batch message" do
    test "pushes a pixel_batch event", %{socket: socket} do
      batch = "fake-batch"
      batch_msgpax = Msgpax.Bin.new(batch)

      send(socket.channel_pid, {:new_change_batch, batch})
      assert_push "pixel_batch", %{:d => ^batch_msgpax}
    end
  end

  defp flush_messages(timeout \\ 100) do
    receive do
      _ -> flush_messages()
    after
      timeout -> nil
    end
  end
end
