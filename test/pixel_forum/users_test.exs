defmodule PixelForum.UsersTest do
  use PixelForum.DataCase, async: true

  alias PixelForum.Repo
  alias PixelForum.Users
  alias PixelForum.Users.User

  @valid_params %{email: "test@example.com", password: "secret1234", password_confirmation: "secret1234"}

  describe "admin-related functions" do
    test "create_admin/2" do
      assert {:ok, user} = Users.create_admin(@valid_params)
      assert user.role == "admin"
    end

    test "set_admin_role/1" do
      assert {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
      assert user.role == "user"

      assert {:ok, user} = Users.set_admin_role(user)
      assert user.role == "admin"
    end

    test "is_admin?/1" do
      refute Users.is_admin?(nil)

      assert {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
      refute Users.is_admin?(user)

      assert {:ok, admin} = Users.create_admin(%{@valid_params | email: "test2@example.com"})
      assert Users.is_admin?(admin)
    end
  end

  describe "API token" do
    test "create_api_token/1 creates new token" do
      assert {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
      assert is_nil(user.api_token_hash)

      assert {:ok, user, api_token} = Users.create_api_token(user)
      assert String.length(api_token) == 64
      refute is_nil(user.api_token_hash)

      fresh_user = Repo.get!(User, user.id)
      assert user.api_token_hash == fresh_user.api_token_hash
    end

    test "verify_token/2 returns :ok when token is correct" do
      assert {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
      assert {:ok, user, api_token} = Users.create_api_token(user)

      assert :ok = Users.verify_api_token(user, api_token)
    end

    test "verify_token/2 returns :error when token is not correct" do
      assert {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
      assert {:ok, user, api_token} = Users.create_api_token(user)

      assert :error = Users.verify_api_token(user, nil)
      assert :error = Users.verify_api_token(user, "incorrect")
      assert :error = Users.verify_api_token(user, String.reverse(api_token))
    end

    test "verify_token/2 fails when user has no token" do
      assert {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
      assert is_nil(user.api_token_hash)

      assert :error = Users.verify_api_token(user, "any-token")
    end

    test "revoke_api_token/2" do
      assert {:ok, user} = Repo.insert(User.changeset(%User{api_token_hash: "1234"}, @valid_params))
      refute is_nil(user.api_token_hash)

      assert {:ok, user} = Users.revoke_api_token(user)
      assert is_nil(user.api_token_hash)

      fresh_user = Repo.get!(User, user.id)
      assert is_nil(fresh_user.api_token_hash)
    end
  end
end
