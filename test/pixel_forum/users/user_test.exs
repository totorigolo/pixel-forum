defmodule PixelForum.Users.UserTest do
  use PixelForum.DataCase

  alias PixelForum.Users.User

  describe "user roles" do
    test "changeset/2 sets default role" do
      user =
        %User{}
        |> User.changeset(%{})
        |> Ecto.Changeset.apply_changes()

      assert user.role == "user"
    end

    test "changeset_role/2 issues an error when the role is invalid" do
      changeset = User.changeset_role(%User{}, %{role: "invalid"})

      assert changeset.errors[:role] ==
               {"is invalid", [validation: :inclusion, enum: ["user", "admin"]]}
    end

    test "changeset_role/2 does not set error when the role is valid" do
      for role <- ~w(user admin) do
        changeset = User.changeset_role(%User{}, %{role: role})
        refute changeset.errors[:role]
      end
    end
  end
end
