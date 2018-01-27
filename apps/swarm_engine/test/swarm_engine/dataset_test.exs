defmodule SwarmEngine.DatasetTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.{Dataset, DataVault, Tracker}


  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DataVault)
  end


  test "creating a dataset by providing name and source" do
    source = LocalFile.create("test/fixtures/dummy.csv")
    columns = MapSet.new(["col_1", "col_2", "col_3"])

    assert  {:ok, %Dataset{ name: "dummy",
                  tracker: %Tracker{},
                  columns: ^columns
                }} = Dataset.create("dummy", source)
  end

  test "creating a dataset by providing name and inexisting source" do
    source = LocalFile.create("test/fixtures/fooooooo.csv")

    assert {:error, :not_found} = Dataset.create("dummy", source)
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

  test "transforming a dataset to a simple map" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    {:ok, dataset} = Dataset.create("goofy", source)

    assert SwarmEngine.Mapable.to_map(dataset)
      == %{
        id: dataset.id,
        decoder: SwarmEngine.Mapable.to_map(dataset.decoder),
        name: "goofy",
        store: SwarmEngine.Mapable.to_map(dataset.store),
        tracker: SwarmEngine.Mapable.to_map(dataset.tracker)
      }
  end

  test "creating a dataset from a simple map" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    {:ok, dataset} = Dataset.create("goofy", source)

    assert (
      dataset
      |> SwarmEngine.Mapable.to_map()
      |> Dataset.from_map()
    ) == dataset
  end
end
