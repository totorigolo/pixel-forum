defmodule PixelForumWeb.Live.AuthHelper do
  @moduledoc """
  This module helps assigning the current user from the session. Doing so will
  setup periodical checks that the session is still active. `session_expired/1`
  will be called when session expires.

  Will not renew the session though, this has to be done separately, by
  periodically fetching a dummy page from for instance.

  Configuration options:

  * `:otp_app` - the app name
  * `:interval` - how often the session has to be checked, defaults 60s

      defmodule MyAppWeb.Live.SomeViewLive do
        use MyAppWeb, :live_view
        use MyAppWeb.Live.AuthHelper, otp_app: my_app

        def mount(params, session, socket) do
          socket = maybe_assign_current_user(socket, session)
          # or
          socket = assign_current_user!(socket, session)

          # ...
        end

        def session_expired(socket) do
          # handle session expiration

          {:noreply, socket}
        end
      end
  """
  require Logger

  alias Pow.Config

  import Phoenix.LiveView, only: [assign: 3]

  @callback session_expired(Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}

  defmacro __using__(opts) do
    config = [otp_app: opts[:otp_app]]
    session_token = Pow.Plug.prepend_with_namespace(config, "auth")
    default_interval_duration = if Mix.env() == :test, do: 100, else: :timer.seconds(60)
    interval = Keyword.get(opts, :interval, default_interval_duration)
    cache_store_backend = Pow.Config.get(config, :cache_store_backend, Pow.Store.Backend.EtsCache)

    config = [
      session_token: session_token,
      interval: interval,
      cache_store_backend: cache_store_backend
    ]

    quote do
      @behaviour unquote(__MODULE__)

      @config unquote(Macro.escape(config)) ++ [module: __MODULE__]

      def maybe_assign_current_user(socket, session),
        do: unquote(__MODULE__).maybe_assign_current_user(socket, self(), session, @config)

      def assign_current_user!(socket, session),
        do: unquote(__MODULE__).assign_current_user!(socket, self(), session, @config)

      def handle_info(:pow_auth_ttl, socket),
        do: unquote(__MODULE__).handle_auth_ttl(socket, self(), @config)

      def refresh_user!(socket),
        do: unquote(__MODULE__).refresh_user!(socket)
    end
  end

  @spec maybe_assign_current_user(Phoenix.LiveView.Socket.t(), pid(), map(), Config.t()) ::
          Phoenix.LiveView.Socket.t()
  def maybe_assign_current_user(socket, pid, session, config) do
    user_session_token = get_user_session_token(socket, session, config)
    user = get_current_user(user_session_token, config)

    # Start the interval check to see if the current user is still connected.
    init_auth_check(socket, pid, config)

    socket
    |> assign_current_user_session_token(user_session_token, config)
    |> assign_current_user(user, config)
  end

  @spec assign_current_user!(Phoenix.LiveView.Socket.t(), pid(), map(), Config.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_current_user!(socket, pid, session, config) do
    socket = maybe_assign_current_user(socket, pid, session, config)
    assign_key = Pow.Config.get(config, :current_user_assigns_key, :current_user)

    if is_nil(socket.assigns[assign_key]) do
      raise "There is no current user in the session."
    end

    socket
  end

  @doc """
  Refresh the user inside the given socket's assigns by fetching it from the
  database. This is useful if the user has been updated externally.
  """
  @spec refresh_user!(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def refresh_user!(socket) do
    current_user_id = socket.assigns.current_user.id
    fresh_user = PixelForum.Repo.get!(PixelForum.Users.User, current_user_id)
    Phoenix.LiveView.assign(socket, current_user: fresh_user)
  end

  # Initiates an Auth check every :interval.
  defp init_auth_check(socket, pid, config) do
    interval = Pow.Config.get(config, :interval)

    if Phoenix.LiveView.connected?(socket) do
      Process.send_after(pid, :pow_auth_ttl, interval)
    end
  end

  # Called on interval when receiving :pow_auth_ttl.
  @spec handle_auth_ttl(Phoenix.LiveView.Socket.t(), pid(), Config.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_auth_ttl(socket, pid, config) do
    interval = Pow.Config.get(config, :interval)
    module = Pow.Config.get(config, :module)
    session_token = get_current_user_session_token(socket, config)

    case get_current_user(session_token, config) do
      nil ->
        Logger.debug("[#{__MODULE__}] User session no longer active")

        socket
        |> assign_current_user_session_token(nil, config)
        |> assign_current_user(nil, config)
        |> module.session_expired()

      _user ->
        Logger.debug("[#{__MODULE__}] User session still active")
        Process.send_after(pid, :pow_auth_ttl, interval)
        {:noreply, socket}
    end
  end

  defp get_user_session_token(socket, session, config) do
    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))
    salt = Atom.to_string(Pow.Plug.Session)

    with {:ok, signed_token} <- Map.fetch(session, config[:session_token]),
         {:ok, session_token} <- Pow.Plug.verify_token(conn, salt, signed_token, config) do
      session_token
    else
      _ -> nil
    end
  end

  defp assign_current_user(socket, user, config) do
    assign_key = Pow.Config.get(config, :current_user_assigns_key, :current_user)
    assign(socket, assign_key, user)
  end

  defp session_token_assign_key(config) do
    current_user_key = Pow.Config.get(config, :current_user_assigns_key, :current_user)
    String.to_atom("#{Atom.to_string(current_user_key)}_session_token")
  end

  defp assign_current_user_session_token(socket, user, config) do
    assign(socket, session_token_assign_key(config), user)
  end

  defp get_current_user_session_token(socket, config) do
    Map.get(socket.assigns, session_token_assign_key(config))
  end

  defp get_current_user(session_token, config) do
    case Pow.Store.CredentialsCache.get([backend: config[:cache_store_backend]], session_token) do
      :not_found -> nil
      {user, _inserted_at} -> user
    end
  end
end
