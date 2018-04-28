defmodule SwarmEngine.RepoTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Repo

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SwarmEngine.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SwarmEngine.DataVault)
  end

  @newDataset %SwarmEngine.DatasetNew{
    id: "c5474362-d018-49a5-a488-eb70e356dd26",
    name: "goofy",
    decoder: SwarmEngine.Decoders.CSV.create(),
    source: SwarmEngine.Endpoints.LocalFile.create("test/fixtures/goofy.csv")
  }

  @dataset %SwarmEngine.Dataset{
    decoder: %SwarmEngine.Decoders.CSV{
      delimiter: "\n",
      headers: true,
      separator: ",",
      type: "CSV"
    },
    id: "c5474362-d018-49a5-a488-eb70e356dd26",
    name: "goofy",
    store: %SwarmEngine.DatasetStore{
      columns: [
        %SwarmEngine.DatasetStoreColumn{
          name: "col_4",
          original: "col_4",
          type: "character varying"
        }
      ],
      name: "_c5474362d01849a5a488eb70e356dd26"
    },
    tracker: %SwarmEngine.Tracker{
      resources:
        MapSet.new([
          %SwarmEngine.Resource{
            modified_at: ~N[2000-01-01 23:00:07.000000],
            name: "goofy.csv",
            size: 42,
            source: %SwarmEngine.Endpoints.LocalFile{
              path: "/tmp/swarm_engine_store/20180408/52833cad-e127-44c8-b66d-281ffa47eb4b.csv",
              type: "LocalFile"
            }
          }
        ]),
      source: %SwarmEngine.Endpoints.LocalFile{
        path: "test/fixtures/goofy.csv",
        type: "LocalFile"
      },
      store: %SwarmEngine.Endpoints.LocalDir{path: "/tmp/swarm_engine_store/"}
    }
  }

  test "putting a new dataset" do
    assert {:ok, @newDataset} == Repo.put_dataset(@newDataset)
  end

  test "putting the same dataset twice" do
    Repo.put_dataset(@newDataset)

    assert {:error, [source: {"has already been taken", []}]} =
             Repo.put_dataset(struct(@newDataset, id: "a12ed994-ca7f-40eb-8ded-f917ce40df59"))
  end

  test "getting a new dataset" do
    Repo.put_dataset(@newDataset)

    assert @newDataset == Repo.get_dataset(@newDataset.id)
  end

  test "putting an initialized dataset" do
    Repo.put_dataset(@newDataset)
    Repo.put_dataset(@dataset)

    assert @dataset == Repo.get_dataset(@dataset.id)
  end

  test "updating a dataset" do
    Repo.put_dataset(@newDataset)
    Repo.put_dataset(@dataset)

    resources =
      MapSet.new([
        %SwarmEngine.Resource{
          modified_at: ~N[2000-01-01 23:00:07.000000],
          name: "goofy.csv",
          size: 42,
          source: %SwarmEngine.Endpoints.LocalFile{
            path: "/tmp/swarm_engine_store/20180408/52833cad-e127-44c8-b66d-281ffa47eb4b.csv",
            type: "LocalFile"
          }
        },
        %SwarmEngine.Resource{
          modified_at: ~N[2005-04-02 23:00:07.000000],
          name: "donald.csv",
          size: 42,
          source: %SwarmEngine.Endpoints.LocalFile{
            path: "other.csv",
            type: "LocalFile"
          }
        }
      ])

    dataset = put_in(@dataset, [:tracker, :resources] |> Enum.map(&Access.key/1), resources)
    Repo.put_dataset(dataset)

    assert dataset == Repo.get_dataset(dataset.id)
  end

  test "retrieving an inexistent dataset" do
    assert nil == Repo.get_dataset("868d2ee4-8578-4fc4-9321-ce5e6864030e")
  end

  test "retrieving a list of datasets when non exist" do
    assert [] == Repo.list_datasets()
  end

  test "retrieving a list of datasets" do
    Repo.put_dataset(@newDataset)
    Repo.put_dataset(@dataset)

    {:ok, new_dataset} =
      Repo.put_dataset(%SwarmEngine.DatasetNew{
        source:
          SwarmEngine.Endpoints.StringIO.create(
            "goofy",
            "col_4,col_5,col_6\nABC,def,123\nKLM,edd,999"
          ),
        decoder: SwarmEngine.Decoders.CSV.create(),
        name: "dummy"
      })

    assert [@dataset, new_dataset] == Repo.list_datasets()
  end
end
