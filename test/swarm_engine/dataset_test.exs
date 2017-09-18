defmodule SwarmEngine.DatasetTest do
  use ExUnit.Case, async: true

  doctest SwarmEngine.Dataset

  alias SwarmEngine.{Dataset, DataVault}

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
end
