defmodule PixelForumWeb.MsgPackUserSocket do
  use Phoenix.Socket,
    serializer: PixelForumWeb.Transports.MessagePackSerializer

  # One day in seconds
  @user_token_validity 86_400

  ## Channels
  channel "image:*", PixelForumWeb.ImageChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(params, socket, _connect_info)

  def connect(%{"user_token" => user_token}, socket, _connect_info) do
    #
    # This is not ideal, as Pow sessions have limited lifetimes that we are ignoring here.
    # See: https://github.com/danschultzer/pow/issues/271
    #
    case Phoenix.Token.verify(socket, "websocket_user_token", user_token, max_age: @user_token_validity) do
      {:ok, user_id} ->
        {:ok,
         socket
         |> assign(:current_user, PixelForum.Repo.get!(PixelForum.Users.User, user_id))
         |> assign(:unique_id, user_id)}

      {:error, _} ->
        :error
    end
  end

  def connect(_params, socket, _connect_info) do
    {:ok, assign(socket, :unique_id, System.unique_integer())}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PixelForumWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
