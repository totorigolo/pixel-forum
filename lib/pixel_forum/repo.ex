defmodule PixelForum.Repo do
  use Ecto.Repo,
    otp_app: :pixel_forum,
    adapter: Ecto.Adapters.Postgres
end
