defmodule PixelForum.Lobbies do
  @moduledoc """
  The Lobbies context.
  """

  import Ecto.Query, warn: false
  alias PixelForum.Repo

  alias PixelForum.Lobbies.Lobby
  alias PixelForum.Lobbies.ForumSupervisor

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
    new_lobby =
      %Lobby{}
      |> Lobby.changeset(attrs)
      |> Repo.insert()

    start_new_lobby_supervisor_tree(new_lobby)

    new_lobby
  end

  defp start_new_lobby_supervisor_tree({:ok, lobby}), do: ForumSupervisor.start_lobby(lobby.id)
  defp start_new_lobby_supervisor_tree(_), do: nil

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
end
