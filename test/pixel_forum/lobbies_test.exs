defmodule PixelForum.LobbiesTest do
  use PixelForum.DataCase

  alias PixelForum.Lobbies

  describe "lobbies" do
    alias PixelForum.Lobbies.Lobby

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def lobby_fixture(attrs \\ %{}) do
      {:ok, lobby} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Lobbies.create_lobby()

      lobby
    end

    test "list_lobbies/0 returns all lobbies" do
      lobby = lobby_fixture()
      assert Lobbies.list_lobbies() == [lobby]
    end

    test "get_lobby!/1 returns the lobby with given id" do
      lobby = lobby_fixture()
      assert Lobbies.get_lobby!(lobby.id) == lobby
    end

    test "create_lobby/1 with valid data creates a lobby" do
      assert {:ok, %Lobby{} = lobby} = Lobbies.create_lobby(@valid_attrs)
      assert lobby.name == "some name"
    end

    test "create_lobby/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lobbies.create_lobby(@invalid_attrs)
    end

    test "update_lobby/2 with valid data updates the lobby" do
      lobby = lobby_fixture()
      assert {:ok, %Lobby{} = lobby} = Lobbies.update_lobby(lobby, @update_attrs)
      assert lobby.name == "some updated name"
    end

    test "update_lobby/2 with invalid data returns error changeset" do
      lobby = lobby_fixture()
      assert {:error, %Ecto.Changeset{}} = Lobbies.update_lobby(lobby, @invalid_attrs)
      assert lobby == Lobbies.get_lobby!(lobby.id)
    end

    test "delete_lobby/1 deletes the lobby" do
      lobby = lobby_fixture()
      assert {:ok, %Lobby{}} = Lobbies.delete_lobby(lobby)
      assert_raise Ecto.NoResultsError, fn -> Lobbies.get_lobby!(lobby.id) end
    end

    test "change_lobby/1 returns a lobby changeset" do
      lobby = lobby_fixture()
      assert %Ecto.Changeset{} = Lobbies.change_lobby(lobby)
    end
  end
end
