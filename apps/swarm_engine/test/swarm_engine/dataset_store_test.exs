defmodule SwarmEngine.DatasetStoreTest do
  use ExUnit.Case, async: true

  doctest SwarmEngine.DatasetStore

  alias SwarmEngine.{DatasetStore, DataVault}
  alias Ecto.Adapters.SQL

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DataVault)
  end

  test "creating a postgres table for a dataset" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    assert {:ok, dataset} = DatasetStore.create(dataset)

    assert {:ok,
            [
              %{order: 1, name: "swarm_id", type: "uuid"},
              %{order: 2, name: "column_1", type: "character varying"},
              %{order: 3, name: "column_2", type: "integer"}
            ]} = DatasetStore.table_columns(dataset)

    assert DatasetStore.exists?(dataset)
  end

  test "creating a dataset that already exists" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    DatasetStore.create(dataset)
    assert {:ok, _} = DatasetStore.create(dataset)
  end

  test "exists? returns false when table does not exist" do
    dataset = %DatasetStore{name: "dummy_table", columns: []}

    refute DatasetStore.exists?(dataset)
  end

  test "columns for a dataset without a table" do
    dataset = %DatasetStore{name: "dummy_table", columns: []}

    assert {:error, :dataset_without_table} = DatasetStore.table_columns(dataset)
  end

  test "inserting into a database" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["bar", 234], ["car", 345], ["tar", 456]]

    DatasetStore.create(dataset)
    DatasetStore.insert(dataset, data)

    assert {:ok,
            %{
              num_rows: 4,
              columns: ["swarm_id", "column_1", "column_2"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  "foo",
                  123
                ],
                [
                  <<146, 133, 207, 198, 58, 39, 183, 29, 135, 228, 210, 35, 155, 232, 147, 130>>,
                  "bar",
                  234
                ],
                [
                  <<245, 229, 38, 130, 173, 136, 244, 190, 161, 221, 177, 65, 220, 212, 222,
                    206>>,
                  "car",
                  345
                ],
                [
                  <<189, 123, 180, 16, 6, 121, 214, 121, 40, 9, 42, 66, 170, 225, 62, 218>>,
                  "tar",
                  456
                ]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table")

    assert {:ok,
            %{
              num_rows: 4,
              columns: ["swarm_id", "version", "loaded_at"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  _,
                  _
                ],
                [
                  <<146, 133, 207, 198, 58, 39, 183, 29, 135, 228, 210, 35, 155, 232, 147, 130>>,
                  _,
                  _
                ],
                [
                  <<245, 229, 38, 130, 173, 136, 244, 190, 161, 221, 177, 65, 220, 212, 222,
                    206>>,
                  _,
                  _
                ],
                [<<189, 123, 180, 16, 6, 121, 214, 121, 40, 9, 42, 66, 170, 225, 62, 218>>, _, _]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table_v")
  end

  test "inserting into a database with version" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["bar", 234], ["car", 345], ["tar", 456]]

    version = DateTime.utc_now()

    DatasetStore.create(dataset)
    DatasetStore.insert(dataset, data, version)

    assert {:ok,
            %{
              num_rows: 4,
              columns: ["swarm_id", "version", "loaded_at"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  version,
                  _
                ],
                [
                  <<146, 133, 207, 198, 58, 39, 183, 29, 135, 228, 210, 35, 155, 232, 147, 130>>,
                  version,
                  _
                ],
                [
                  <<245, 229, 38, 130, 173, 136, 244, 190, 161, 221, 177, 65, 220, 212, 222,
                    206>>,
                  version,
                  _
                ],
                [
                  <<189, 123, 180, 16, 6, 121, 214, 121, 40, 9, 42, 66, 170, 225, 62, 218>>,
                  version,
                  _
                ]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table_v")
  end

  test "retrieving dataset versions" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["bar", 234], ["car", 345], ["tar", 456]]

    version_1 = DateTime.utc_now()
    version_2 = DateTime.from_naive!(~N[2016-05-24 13:26:08.000000], "Etc/UTC")

    DatasetStore.create(dataset)

    DatasetStore.insert(dataset, data, version_1)
    DatasetStore.insert(dataset, data, version_2)

    assert DatasetStore.versions(dataset) == [version_1, version_2]
  end

  test "inserting a dataset twice with the same version" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["bar", 234], ["car", 345], ["tar", 456]]

    version = DateTime.utc_now()

    DatasetStore.create(dataset)
    DatasetStore.insert(dataset, data, version)
    DatasetStore.insert(dataset, data, version)

    assert {:ok,
            %{
              num_rows: 4,
              columns: ["swarm_id", "column_1", "column_2"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  "foo",
                  123
                ],
                [
                  <<146, 133, 207, 198, 58, 39, 183, 29, 135, 228, 210, 35, 155, 232, 147, 130>>,
                  "bar",
                  234
                ],
                [
                  <<245, 229, 38, 130, 173, 136, 244, 190, 161, 221, 177, 65, 220, 212, 222,
                    206>>,
                  "car",
                  345
                ],
                [
                  <<189, 123, 180, 16, 6, 121, 214, 121, 40, 9, 42, 66, 170, 225, 62, 218>>,
                  "tar",
                  456
                ]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table")

    assert {:ok,
            %{
              num_rows: 4,
              columns: ["swarm_id", "version", "loaded_at"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  version,
                  _
                ],
                [
                  <<146, 133, 207, 198, 58, 39, 183, 29, 135, 228, 210, 35, 155, 232, 147, 130>>,
                  version,
                  _
                ],
                [
                  <<245, 229, 38, 130, 173, 136, 244, 190, 161, 221, 177, 65, 220, 212, 222,
                    206>>,
                  version,
                  _
                ],
                [
                  <<189, 123, 180, 16, 6, 121, 214, 121, 40, 9, 42, 66, 170, 225, 62, 218>>,
                  version,
                  _
                ]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table_v")
  end

  test "inserting duplicates inserts unique records" do
    dataset = %DatasetStore{
      name: "test_table",
      columns: [
        %{name: "column_1", type: "varchar"},
        %{name: "column_2", type: "integer"}
      ]
    }

    data = [["foo", 123], ["foo", 123]]

    DatasetStore.create(dataset)
    DatasetStore.insert(dataset, data)

    assert {:ok,
            %{
              num_rows: 1,
              columns: ["swarm_id", "column_1", "column_2"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  "foo",
                  123
                ]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table")

    assert {:ok,
            %{
              num_rows: 2,
              columns: ["swarm_id", "version", "loaded_at"],
              rows: [
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  _,
                  _
                ],
                [
                  <<239, 35, 142, 160, 10, 38, 82, 141, 228, 15, 242, 49, 229, 169, 127, 80>>,
                  _,
                  _
                ]
              ]
            }} = SQL.query(DataVault, "SELECT * FROM test_table_v")
  end
end
