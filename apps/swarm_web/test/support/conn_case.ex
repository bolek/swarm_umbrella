defmodule SwarmWeb.ConnCase do
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
          nil -> put_in(context[:user], %{id: 123})
          _ -> context
        end

        conn = conn
        |> Plug.Test.init_test_session(current_user: context.user.id)

        put_in(context[:conn], conn)
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
