defmodule PixelForum.Lobbies do
  @moduledoc """
  The Lobbies context.
  """

  import Ecto.Query, warn: false
  alias PixelForum.Repo

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
