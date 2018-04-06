defmodule SwarmEngine.RepoTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Repo

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SwarmEngine.Repo)
  end

  @newDataset %SwarmEngine.DatasetNew{
    id: "c5474362-d018-49a5-a488-eb70e356dd26",
    name: "goofy",
    decoder: SwarmEngine.Decoders.CSV.create(),
    source: SwarmEngine.Connectors.LocalFile.create("test/fixtures/goofy.csv")
  }

  test "putting a new dataset" do
    assert {:ok, @newDataset} == Repo.put_dataset(@newDataset)
  end

  test "putting the same dataset twice" do
    Repo.put_dataset(@newDataset)

    assert {:error, %{errors: [source: {"has already been taken", []}]}}
      = Repo.put_dataset(struct(@newDataset, id: "a12ed994-ca7f-40eb-8ded-f917ce40df59"))
  end
end
