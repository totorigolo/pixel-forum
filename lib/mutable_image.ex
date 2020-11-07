defmodule MutableImage do
  use Rustler, otp_app: :pixel_forum, crate: "mutableimage"

  @typep opaque_hack(a) :: a
  @opaque mutable_image :: opaque_hack(any)

  @type coordinate :: {integer(), integer()}

  @type color :: {integer(), integer(), integer()}

  @spec new(integer(), integer()) :: {:ok, mutable_image} | {:error, atom}
  def new(_width, _height), do: :erlang.nif_error(:nif_not_loaded)

  @spec change_pixel(mutable_image, coordinate, color) :: :ok | {:error, atom}
  def change_pixel(_mutable_image, _coordinate, _color), do: :erlang.nif_error(:nif_not_loaded)

  @spec as_png(mutable_image) :: {:ok, binary()}
  def as_png(_mutable_image), do: :erlang.nif_error(:nif_not_loaded)
end
