defmodule PixelForum.Forum.LobbyManagerTest do
  use PixelForum.DataCase, async: true

  describe "PixelForum.Forum.LobbyManager" do
    alias PixelForum.Forum.LobbyManager
    alias PixelForum.Lobbies.Lobby

    @tag capture_log: true
    test "cannot start a lobby supervisor for a given lobby more than once" do
      lobby_id = Ecto.UUID.generate()
      {:ok, lobby_pid} = LobbyManager.start_lobby(lobby_id)
      on_exit(fn -> LobbyManager.stop_lobby(lobby_id) end)
      {:error, {:already_started, ^lobby_pid}} = LobbyManager.start_lobby(lobby_id)
    end

    test "can stop started lobbies" do
      lobby_id = Ecto.UUID.generate()
      {:ok, lobby_pid} = LobbyManager.start_lobby(lobby_id)
      assert is_pid(lobby_pid)
      :ok = LobbyManager.stop_lobby(lobby_id)
      refute Process.alive?(lobby_pid)
    end

    test "stops lobbies on :lobby_deleted PubSub event" do
      lobby_id = Ecto.UUID.generate()
      {:ok, lobby_pid} = LobbyManager.start_lobby(lobby_id)

      Phoenix.PubSub.broadcast(
        PixelForum.PubSub,
        "lobbies",
        {:lobby_deleted, %Lobby{id: lobby_id}}
      )

      await_false(fn -> Process.info(lobby_pid, :message_queue_len) == {:message_queue_len, 0} end)
      await_false(fn -> Process.alive?(lobby_pid) end)
    end
  end

  defp await_false(func, _ \\ true)
  defp await_false(_func, false), do: :ok
  defp await_false(func, _), do: await_false(func, func.())
end
