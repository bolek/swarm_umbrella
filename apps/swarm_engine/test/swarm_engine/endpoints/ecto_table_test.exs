defmodule SwarmEngine.Endpoints.EctoTableTest do
  use SwarmEngine.DataCase

  alias SwarmEngine.Endpoints.EctoTable
  alias Ecto.Adapters.SQL

  test "streaming SwarmEngine messages into a EctoTable endpoint" do
    SQL.query(SwarmEngine.DataVault, """
      CREATE TABLE test_endpoint_table (
        a int,
        b int,
        c varchar
      );
    """)

    target_endpoint = EctoTable.create("SwarmEngine.DataVault", "test_endpoint_table")

    [%{a: 1, b: 2, c: "string"}, %{a: 2, b: 3, c: "other string"}]
    |> Stream.map(&SwarmEngine.Message.create(&1, %{}))
    |> SwarmEngine.Producer.into(target_endpoint)
    |> Stream.run()

    assert {:ok, %Postgrex.Result{rows: [[1, 2, "string"], [2, 3, "other string"]]}} =
             SQL.query(SwarmEngine.DataVault, "SELECT * FROM test_endpoint_table")
  end

  test "streaming SwarmEngine messages from an EctoTable endpoint" do
    SQL.query(SwarmEngine.DataVault, """
      CREATE TABLE test_endpoint_table (
        a int,
        b int,
        c varchar
      );
    """)

    SQL.query(SwarmEngine.DataVault, """
      INSERT INTO test_endpoint_table(a,b,c) VALUES(1,2,'a'),(2,3,'b');
    """)

    source_endpoint = EctoTable.create("SwarmEngine.DataVault", "test_endpoint_table")

    assert {:ok,
            [
              %SwarmEngine.Message{
                body: [[1, 2, "a"], [2, 3, "b"]],
                headers: %{columns: ["a", "b", "c"]}
              }
            ]} =
             SwarmEngine.DataVault.transaction(fn ->
               SwarmEngine.Consumer.stream(source_endpoint)
               |> Enum.to_list()
             end)
  end
end
