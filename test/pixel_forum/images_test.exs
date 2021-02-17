defmodule PixelForum.ImagesTest do
  use PixelForum.DataCase, async: true

  alias PixelForum.Images

  describe "images" do
    alias PixelForum.Images

    use PixelForum.Fixtures, [:lobby, :image]

    test "get_all_lobby_images/1 returns all images for the given lobby" do
      lobby_1 = lobby_fixture(%{name: "A"})
      lobby_1_image_1 = image_fixture(lobby_1.id, %{version: 11})
      lobby_1_image_2 = image_fixture(lobby_1.id, %{version: 12})

      lobby_2 = lobby_fixture(%{name: "B"})
      _lobby_2_image_1 = image_fixture(lobby_2.id, %{version: 21})
      _lobby_2_image_2 = image_fixture(lobby_2.id, %{version: 22})

      assert Images.get_all_lobby_images!(lobby_1.id) == [lobby_1_image_1, lobby_1_image_2]
    end
  end
end
