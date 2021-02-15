defmodule PixelForum.Images do
  @moduledoc """
  The Lobbies context.
  """

  import Ecto.Query, warn: false
  alias PixelForum.Repo

  require Logger

  alias PixelForum.Images.Image
  alias PixelForum.Lobbies.Lobby

  def get_all_lobby_images!(lobby_id), do: Image |> where(lobby_id: ^lobby_id) |> Repo.all()

  def get_current_lobby_image(nil), do: nil
  def get_current_lobby_image(%Lobby{image_version: nil}), do: nil

  def get_current_lobby_image(%Lobby{id: lobby_id, image_version: image_version} = lobby) do
    query =
      from i in Image,
        select: i,
        where: i.lobby_id == ^lobby_id and i.version == ^image_version

    image = Repo.one(query)
    if is_nil(image), do: Logger.alert("No image for lobby: #{lobby}")
    image
  end
end
