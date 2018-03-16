defmodule SwarmWeb.ApiCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import SwarmWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint SwarmWeb.Endpoint

      def sign_in(%{conn: conn} = context) do
        context = case context[:user] do
          nil ->
            {:ok, user } = Swarm.Accounts.create_user(%{name: "Johnny", credential: %{email: "b@b.com", password: "testtest"}})
            put_in(context[:user], user)
          _ -> context
        end

        {:ok, token, _claims} = SwarmWeb.Auth.Guardian.encode_and_sign(context[:user])
        conn = conn |> put_req_header("authorization", "Bearer #{token}")

        context[:conn]
        |> put_in(conn)
      end
    end
  end


  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Swarm.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Swarm.Repo, {:shared, self()})
    end
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

end
