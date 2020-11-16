defmodule PixelForumWeb.Pow.Messages do
  use Pow.Phoenix.Messages
  use Pow.Extension.Phoenix.Messages,
    extensions: [PowAssent]

  import PixelForumWeb.Gettext

  @impl true
  def user_not_authenticated(_conn), do: gettext("You must be logged in.")
end
