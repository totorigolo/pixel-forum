defmodule MutableImage do
  use Rustler, otp_app: :pixel_forum, crate: "mutableimage"

  @typep opaque_hack(a) :: a
  @opaque mutable_image :: opaque_hack(reference())

  @type coordinate :: {non_neg_integer(), non_neg_integer()}

  @type color :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}

  @spec new(integer(), integer()) :: {:ok, mutable_image} | {:error, atom}
  def new(_width, _height), do: :erlang.nif_error(:nif_not_loaded)

  @spec change_pixel(mutable_image, coordinate, color) :: :ok | {:error, atom}
  def change_pixel(_mutable_image, _coordinate, _color), do: :erlang.nif_error(:nif_not_loaded)

  @spec as_png(mutable_image) :: {:ok, binary()}
  def as_png(_mutable_image), do: :erlang.nif_error(:nif_not_loaded)

  @spec valid_coordinate?(coordinate()) :: boolean()
  def valid_coordinate?({x, y}) when is_integer(x) and is_integer(y) and x >= 0 and y >= 0, do: true
  def valid_coordinate?(_), do: false

  defguardp is_u8(value) when is_integer(value) and 0 <= value and value <= 255

  @spec valid_color?(color()) :: boolean()
  def valid_color?({r, g, b}) when is_u8(r) and is_u8(g) and is_u8(b), do: true
  def valid_color?(_), do: false
end
