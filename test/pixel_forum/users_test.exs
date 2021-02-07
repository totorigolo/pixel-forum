defmodule PixelForum.UsersTest do
  use PixelForum.DataCase, async: true

  alias PixelForum.Repo
  alias PixelForum.Users
  alias PixelForum.Users.User

  @valid_params %{
    email: "test@example.com",
    password: "secret1234",
    password_confirmation: "secret1234"
  }

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

  describe "Access token" do
    setup [:create_user]

    setup do
      {:ok, _pid} = start_supervised(PixelForum.Test.JokenTimeMock)
      :ok
    end

    test "create_access_token/1 creates new verifiable token", %{user: user} do
      assert {:ok, access_token} = Users.create_access_token(user)
      assert {:ok, _claims} = Users.verify_access_token(access_token)
    end

    test "verify_access_token/2 returns the claims when token is correct", %{user: user} do
      assert {:ok, access_token} = Users.create_access_token(user)

      assert {:ok, claims} = Users.verify_access_token(access_token)
      assert claims["sub"] == user.id
      assert claims["role"] == user.role
    end

    test "verify_access_token/2 errors when invalid signature", %{user: user} do
      assert {:ok, access_token} = Users.create_access_token(user)
      assert {:error, :signature_error} = Users.verify_access_token(access_token <> "?")
    end

    test "verify_access_token/2 errors when token is expired", %{user: user} do
      assert {:ok, access_token} = Users.create_access_token(user)

      two_days = 2 * 24 * 60 * 60
      PixelForum.Test.JokenTimeMock.advance(two_days)

      assert {:error, joken_reason} = Users.verify_access_token(access_token)
      assert joken_reason[:claim] == "exp"
      assert joken_reason[:message] =~ "Invalid token"
    end
  end

  defp create_user(_) do
    {:ok, user} = Repo.insert(User.changeset(%User{}, @valid_params))
    {:ok, user: user}
  end
end
