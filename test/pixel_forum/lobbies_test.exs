defmodule PixelForum.LobbiesTest do
  use PixelForum.DataCase,
    # Those tests cannot be async because some of them start new processes.
    async: false

  alias PixelForum.Lobbies

  describe "lobbies" do
    alias PixelForum.Lobbies.Lobby

    use PixelForum.Fixtures, [:lobby]

    test "list_lobbies/0 returns all lobbies" do
      lobby = lobby_fixture()
      assert Lobbies.list_lobbies() == [lobby]
    end

    test "get_lobby!/1 returns the lobby with given id" do
      lobby = lobby_fixture()
      assert Lobbies.get_lobby!(lobby.id) == lobby
    end

    test "create_lobby/1 with valid data creates a lobby" do
      assert {:ok, %Lobby{} = lobby} = Lobbies.create_lobby(create_attrs(:lobby))
      assert lobby.name == "some name"
    end

    @tag capture_log: true
    test "create_lobby/1 with valid data starts a lobby supervisor" do
      assert {:ok, %Lobby{id: lobby_id}} = Lobbies.create_lobby(create_attrs(:lobby))
      assert :ignore = PixelForum.Forum.LobbyManager.start_lobby(lobby_id)
    end

    test "create_lobby/1 broadcasts a :lobby_created PubSub event" do
      Lobbies.subscribe()
      assert {:ok, %Lobby{id: lobby_id}} = Lobbies.create_lobby(create_attrs(:lobby))
      assert_receive {:lobby_created, %Lobby{id: ^lobby_id}}
    end

    test "create_lobby/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lobbies.create_lobby(invalid_attrs(:lobby))
    end

    test "update_lobby/2 with valid data updates the lobby" do
      lobby = lobby_fixture()
      assert {:ok, %Lobby{} = lobby} = Lobbies.update_lobby(lobby, update_attrs(:lobby))
      assert lobby.name == "some updated name"
    end

    test "update_lobby/2 broadcasts a :lobby_updated PubSub event" do
      lobby = lobby_fixture()
      Lobbies.subscribe()
      assert {:ok, %Lobby{id: lobby_id}} = Lobbies.update_lobby(lobby, update_attrs(:lobby))
      assert_receive {:lobby_updated, %Lobby{id: ^lobby_id}}
    end

    test "update_lobby/2 with invalid data returns error changeset" do
      lobby = lobby_fixture()
      assert {:error, %Ecto.Changeset{}} = Lobbies.update_lobby(lobby, invalid_attrs(:lobby))
      assert lobby == Lobbies.get_lobby!(lobby.id)
    end

    test "delete_lobby/1 deletes the lobby" do
      lobby = lobby_fixture()
      assert {:ok, %Lobby{}} = Lobbies.delete_lobby(lobby)
      assert_raise Ecto.NoResultsError, fn -> Lobbies.get_lobby!(lobby.id) end
    end

    test "delete_lobby/1 broadcasts a :lobby_deleted PubSub event" do
      lobby = lobby_fixture()
      Lobbies.subscribe()
      assert {:ok, %Lobby{id: lobby_id}} = Lobbies.delete_lobby(lobby)
      assert_receive {:lobby_deleted, %Lobby{id: ^lobby_id}}
    end

    test "change_lobby/1 returns a lobby changeset" do
      lobby = lobby_fixture()
      assert %Ecto.Changeset{} = Lobbies.change_lobby(lobby)
    end

    test "reset_lobby_image/1 broadcasts a :lobby_image_reset PubSub event" do
      lobby = lobby_fixture()
      Lobbies.subscribe()
      assert {:ok, ^lobby} = Lobbies.reset_lobby_image(lobby.id)
      assert_receive {:lobby_image_reset, ^lobby}
    end
  end
end
