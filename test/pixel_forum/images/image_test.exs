defmodule PixelForum.Images.ImageTest do
  use ExUnit.Case, async: true

  alias PixelForum.Images.Image

  use PixelForum.Fixtures, [:image]

  describe "new_image_changeset" do
    @png_header <<0x89, "PNG", "\r\n", 0x1A, "\n">>

    test "accepts valid PNG" do
      attrs =
        %{png_blob: @png_header <> "some-fake-data"}
        |> Enum.into(create_attrs(:image))

      changeset = Image.new_image_changeset("lobby", attrs)
      assert changeset.valid?
    end

    test "refuses invalid PNG" do
      attrs =
        %{png_blob: "?" <> @png_header <> "some-fake-data"}
        |> Enum.into(create_attrs(:image))

      changeset = Image.new_image_changeset("lobby", attrs)
      refute changeset.valid?
    end
  end
end
