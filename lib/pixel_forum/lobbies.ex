defmodule PixelForum.Lobbies do
  @moduledoc """
  The Lobbies context.
  """

  import Ecto.Query, warn: false
  alias PixelForum.Repo

  require Logger

  alias PixelForum.Images
  alias PixelForum.Images.Image
  alias PixelForum.Lobbies.Lobby

  @doc """
  Returns the list of lobbies.

  ## Examples

      iex> list_lobbies()
      [%Lobby{}, ...]

  """
  def list_lobbies do
    Repo.all(Lobby)
  end

  @doc """
  Gets a single lobby.

  Raises `Ecto.NoResultsError` if the Lobby does not exist.

  ## Examples

      iex> get_lobby!(123)
      %Lobby{}

      iex> get_lobby!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lobby!(id), do: Repo.get!(Lobby, id)

  @doc """
  Creates a lobby.

  ## Examples

      iex> create_lobby(%{field: value})
      {:ok, %Lobby{}}

      iex> create_lobby(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lobby(attrs \\ %{}) do
    %Lobby{}
    |> Lobby.changeset(attrs)
    |> Repo.insert()
    # Manually start the supervisor tree instead of using the PubSub event as it
    # needs to be started when the other subscribers receive the event.
    |> start_new_lobby_supervisor_tree()
    |> broadcast(:lobby_created)
  end

  defp start_new_lobby_supervisor_tree({:ok, lobby}) do
    PixelForum.Forum.LobbyManager.start_lobby(lobby.id)
    {:ok, lobby}
  end

  defp start_new_lobby_supervisor_tree({:error, _reason} = error), do: error

  @doc """
  Updates a lobby.

  ## Examples

      iex> update_lobby(lobby, %{field: new_value})
      {:ok, %Lobby{}}

      iex> update_lobby(lobby, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lobby(%Lobby{} = lobby, attrs) do
    lobby
    |> Lobby.changeset(attrs)
    |> Repo.update()
    |> broadcast(:lobby_updated)
  end

  @doc """
  Deletes a lobby.

  ## Examples

      iex> delete_lobby(lobby)
      {:ok, %Lobby{}}

      iex> delete_lobby(lobby)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lobby(%Lobby{} = lobby) do
    Repo.delete(lobby)
    |> broadcast(:lobby_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lobby changes.

  ## Examples

      iex> change_lobby(lobby)
      %Ecto.Changeset{data: %Lobby{}}

  """
  def change_lobby(%Lobby{} = lobby, attrs \\ %{}) do
    Lobby.changeset(lobby, attrs)
  end

  @doc """
  Resets the lobby image.
  """
  @spec reset_lobby_image(String.t()) :: {:ok, Lobby.t()}
  def reset_lobby_image(lobby_id) when is_binary(lobby_id) do
    lobby = get_lobby!(lobby_id)
    :ok = PixelForum.Images.ImageServer.reset_image(lobby.id)
    # TODO: Persist the new reset image
    broadcast({:ok, lobby}, :lobby_image_reset)
  end

  @spec get_current_lobby_image(String.t()) :: Images.Image.t()
  def get_current_lobby_image(lobby_id) when is_binary(lobby_id) do
    get_lobby!(lobby_id)
    |> Images.get_current_lobby_image()
  end

  @spec update_lobby_image(Lobby.t() | String.t(), non_neg_integer(), binary()) ::
          {:ok, Lobby.t(), Image.t()} | :ignore | :error
  def update_lobby_image(%Lobby{} = lobby, new_image_version, png_blob) do
    Logger.info("Saving lobby #{lobby.id} image version #{new_image_version}.")

    if not is_nil(lobby.image_version) and lobby.image_version >= new_image_version do
      # Consistency: this does work with concurrent writes because the
      # optimistic lock will refuse updates if the lobby version is not up-to-date.
      if lobby.image_version == new_image_version do
        Logger.info("Ignoring lobby image update: this version is the same.")
      else
        current = lobby.image_version
        new = new_image_version
        Logger.warn("NOT saving image because the version is old (#{current} < #{new}).")
      end

      :ignore
    else
      result =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :image,
          Image.new_image_changeset(lobby.id, %{
            version: new_image_version,
            png_blob: png_blob,
            date: NaiveDateTime.utc_now()
          })
        )
        |> Ecto.Multi.update(:lobby, Lobby.change_version_changeset(lobby, new_image_version))
        |> Repo.transaction()

      case result do
        {:ok, %{image: %{version: version} = image, lobby: lobby}} ->
          Logger.info("Successfully saved image for #{lobby.id}, version is #{version}.")
          {:ok, lobby, image}

        {:error, failed_operation, failed_value, changes_so_far} ->
          hint =
            case failed_operation do
              :image -> "Hint: is the DB full?"
              :lobby -> "Hint: this is likely caused by a concurrent update"
            end

          # TODO: Retry when optimistic locking fails

          failure = "Failure: " <> inspect(failed_value, pretty: true)
          so_far = "Successful changes (rolled back): " <> inspect(changes_so_far, pretty: true)

          error_message =
            Enum.join(["Failed to save the image for #{lobby.id}.", failure, hint, so_far], "\n")

          Logger.critical(error_message)
          :error
      end
    end
  end

  def update_lobby_image(lobby_id, new_image_version, png_blob) when is_binary(lobby_id) do
    get_lobby!(lobby_id)
    |> update_lobby_image(new_image_version, png_blob)
  end

  @doc """
  Subscribes the current process to the "lobbies" topic.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(PixelForum.PubSub, "lobbies")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, lobby}, event) do
    Phoenix.PubSub.broadcast(PixelForum.PubSub, "lobbies", {event, lobby})
    {:ok, lobby}
  end
end
