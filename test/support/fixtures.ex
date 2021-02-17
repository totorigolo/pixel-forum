defmodule PixelForum.Fixtures do
  @moduledoc """
  Use this module to import the fixtures you need in your tests:

      use PixelForum.Fixtures, [:lobby]
  """

  def lobby do
    alias PixelForum.Lobbies

    quote do
      def create_attrs(:lobby), do: %{name: "some name"}
      def update_attrs(:lobby), do: %{name: "some updated name"}
      def invalid_attrs(:lobby), do: %{name: nil}

      def lobby_fixture(attrs \\ %{}) do
        {:ok, lobby} =
          attrs
          |> Enum.into(create_attrs(:lobby))
          |> Lobbies.create_lobby()

        lobby
      end
    end
  end

  def image do
    alias PixelForum.Repo
    alias PixelForum.Images.Image

    fake_png = <<0x89, "PNG", "\r\n", 0x1A, "\n", "fake-png">> |> Macro.escape()

    quote do
      def create_attrs(:image),
        do: %{version: 123, date: NaiveDateTime.utc_now(), png_blob: unquote(fake_png)}

      def image_fixture(lobby_id, attrs \\ %{}) do
        {:ok, image} =
          Image.new_image_changeset(lobby_id, Enum.into(attrs, create_attrs(:image)))
          |> Repo.insert()

        image
      end
    end
  end

  defmacro __using__(fixtures) when is_list(fixtures) do
    for fixture <- fixtures, is_atom(fixture), do: apply(__MODULE__, fixture, [])
  end
end
