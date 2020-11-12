# Inspiration: https://nerds.stoiximan.gr/2016/11/23/binary-data-over-phoenix-sockets/
# But adapted to use the same data as Phoenix.Socket.V2.JSONSerializer

defmodule PixelForumWeb.Transports.MessagePackSerializer do
  @moduledoc false
  @behaviour Phoenix.Socket.Serializer

  alias Phoenix.Socket.{Broadcast, Message, Reply}

  @impl true
  def fastlane!(%Broadcast{} = msg) do
    data = Msgpax.pack!([nil, nil, msg.topic, msg.event, msg.payload])
    {:socket_push, :binary, data}
  end

  @impl true
  def encode!(%Reply{} = reply) do
    packed =
      [
        reply.join_ref,
        reply.ref,
        reply.topic,
        "phx_reply",
        %{status: reply.status, response: reply.payload}
      ]
      |> Msgpax.pack!()

    {:socket_push, :binary, packed}
  end

  @impl true
  def encode!(%Message{} = msg) do
    data = [msg.join_ref, msg.ref, msg.topic, msg.event, msg.payload]
    {:socket_push, :binary, Msgpax.pack!(data)}
  end

  # Messages received from the clients are still in JSON format.
  @impl true
  def decode!(raw_message, opts) do
    Phoenix.Socket.V2.JSONSerializer.decode!(raw_message, opts)
  end
end
