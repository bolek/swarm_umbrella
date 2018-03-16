defmodule SwarmEngine.DatasetTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.{Dataset, DataVault, Tracker}


  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DataVault)
  end

  test "stream a dataset" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    {:ok, dataset} = Dataset.create("goofy", source)

    assert  [%{"col_4" => "ABC", "col_5" => "def", "col_6" => "123"},
             %{"col_4" => "KLM", "col_5" => "edd", "col_6" => "678"}] =
      Dataset.stream(dataset) |> Enum.to_list
  end

  test "syncing dataset with no changes" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    {:ok, dataset} = Dataset.create("goofy", source)

    {:ok, synced_dataset} = Dataset.sync(dataset)

    assert synced_dataset == dataset
  end

  test "syncing dataset with updated resource with different columns" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    {:ok, dataset} = Dataset.create("goofy", source)
    new_tracker = LocalFile.create("test/fixtures/dummy.csv")
      |> Tracker.create(%LocalDir{path: "tmp/"})

    dataset = %{dataset | tracker: new_tracker}

    assert {:error, "no common columns"} = Dataset.sync(dataset)
  end

  test "loading the current version of a csv resource" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    {:ok, dataset} = Dataset.create("goofy", source)

    assert Dataset.load(dataset) == :ok
  end
end
