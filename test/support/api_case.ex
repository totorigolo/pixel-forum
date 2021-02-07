defmodule PixelForumWeb.ApiCase do
  @moduledoc """
  This module is based on ConnCase, and is made for testing JSON REST APIs.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import PixelForumWeb.ConnCase

      alias PixelForumWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint PixelForumWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PixelForum.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PixelForum.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  setup %{conn: conn} do
    {:ok,
     conn:
       conn
       |> Plug.Conn.put_req_header("accept", "application/json")
       |> Plug.Conn.put_req_header("content-type", "application/json")}
  end
end
