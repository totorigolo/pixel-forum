defmodule PixelForum.Forum.SupervisorTest do
  use ExUnit.Case,
    # Not async because we will mess up with a supervisor and global processes.
    async: false

  describe "PixelForum.Forum.Supervisor" do
    test "only restart LobbyManager when LobbyManager dies" do
      lobby_registry_pid = Process.whereis(PixelForum.Forum.LobbyRegistry)
      lobby_supervisor_pid = Process.whereis(PixelForum.Forum.LobbySupervisor)

      lobby_manager_pid = Process.whereis(PixelForum.Forum.LobbyManager)
      Process.exit(lobby_manager_pid, :normal)
      wait_started(PixelForum.Forum.LobbyManager)

      assert lobby_registry_pid == Process.whereis(PixelForum.Forum.LobbyRegistry)
      assert lobby_supervisor_pid == Process.whereis(PixelForum.Forum.LobbySupervisor)
    end

    @tag capture_log: true
    test "lobby supervisors survive LobbyManager restarts" do
      lobby_id = "fake-id"
      {:ok, lobby_pid} = PixelForum.Forum.LobbyManager.start_lobby(lobby_id)

      lobby_manager_pid = Process.whereis(PixelForum.Forum.LobbyManager)
      Process.exit(lobby_manager_pid, :normal)
      {:ok, _pid} = wait_started(PixelForum.Forum.LobbyManager)

      assert {:error, {:already_started, lobby_pid}} ==
               PixelForum.Forum.LobbyManager.start_lobby(lobby_id)
      assert :ok == DynamicSupervisor.terminate_child(PixelForum.Forum.LobbySupervisor, lobby_pid)
    end
  end

  defp wait_started(name), do: wait_started(name, nil)
  defp wait_started(name, nil), do: wait_started(name, Process.whereis(name))
  defp wait_started(_name, pid) when is_pid(pid), do: {:ok, pid}
end
