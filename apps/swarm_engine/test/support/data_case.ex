defmodule SwarmEngine.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias SwarmEngine.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import SwarmEngine.DataCase
    end
  end

  setup tags do
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(SwarmEngine.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(SwarmEngine.DataVault, {:shared, self()})
    end

    on_exit(fn ->
      SwarmEngine.Repo.delete_all(SwarmEngine.Repo.Schema.Dataset)

      {:ok, %{rows: rows}} =
        Ecto.Adapters.SQL.query(SwarmEngine.DataVault, """
             SELECT tablename
             FROM pg_tables
             WHERE schemaname = 'public'
             AND tablename <> 'schema_migrations'
        """)

      rows
      |> Enum.each(fn table ->
        Ecto.Adapters.SQL.query(SwarmEngine.DataVault, """
          DROP TABLE #{table};
        """)
      end)
    end)

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
