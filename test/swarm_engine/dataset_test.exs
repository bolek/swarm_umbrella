defmodule SwarmEngine.DatasetTest do
  use ExUnit.Case, async: true

  doctest SwarmEngine.Dataset

  alias SwarmEngine.{Dataset, DataVault}
  alias Ecto.Adapters.SQL

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DataVault)
  end

  test "creating a postgres table for a dataset" do
    dataset = %Dataset{name: "test_table", columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    assert :ok = Dataset.create(dataset)

    assert {:ok, [
      %{order: 1, name: "_id", type: "uuid"},
      %{order: 2, name: "column_1", type: "character varying"},
      %{order: 3, name: "column_2", type: "integer"},
      %{order: 4, name: "_created_at", type: "timestamp with time zone"},
      %{order: 5, name: "_full_hash", type: "character varying"},
    ]} = Dataset.columns(dataset)

    assert Dataset.exists?(dataset)
  end

  test "creating a dataset that already exists" do
    dataset = %Dataset{name: "test_table", columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    Dataset.create(dataset)
    assert :ok = Dataset.create(dataset)
  end

  test "exists? returns false when table does not exist" do
    dataset = %Dataset{name: "dummy_table", columns: []}

    refute Dataset.exists?(dataset)
  end

  test "columns for a dataset without a table" do
    dataset = %Dataset{name: "dummy_table", columns: []}

    assert {:error, :dataset_without_table} = Dataset.columns(dataset)
  end

  test "inserting into a database" do
    dataset = %Dataset{name: "test_table", columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["bar", 234], ["car", 345], ["tar", 456]]

    Dataset.create(dataset)
    Dataset.insert(dataset, data)

    assert {:ok,
            %{
              num_rows: 4,
              columns: ["_id", "column_1", "column_2", "_created_at", "_full_hash"],
              rows: [
                [_, "foo", 123, _, "7yOOoAomUo3kD/Ix5al/UA=="],
                [_, "bar", 234, _, "koXPxjontx2H5NIjm+iTgg=="],
                [_, "car", 345, _, "9eUmgq2I9L6h3bFB3NTezg=="],
                [_, "tar", 456, _, "vXu0EAZ51nkoCSpCquE+2g=="]
              ]
            }
          } = SQL.query(DataVault, "SELECT * FROM test_table")
  end

  test "inserting duplicates inserts unique records" do
    dataset = %Dataset{name: "test_table", columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["foo", 123]]

    Dataset.create(dataset)
    Dataset.insert(dataset, data)

    assert {:ok,
            %{
              num_rows: 1,
              columns: ["_id", "column_1", "column_2", "_created_at", "_full_hash"],
              rows: [
                [_, "foo", 123, _, "7yOOoAomUo3kD/Ix5al/UA=="]
              ]
            }
          } = SQL.query(DataVault, "SELECT * FROM test_table")
  end
end
