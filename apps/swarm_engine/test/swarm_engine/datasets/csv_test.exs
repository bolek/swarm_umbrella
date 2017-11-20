defmodule SwarmEngine.Datasets.CSVTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.Datasets.CSV
  alias SwarmEngine.{DataVault, Tracker}


  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DataVault)
  end


  test "creating a CSV dataset by providing name and source" do
    source = LocalFile.create("test/fixtures/dummy.csv")
    columns = MapSet.new(["col_1", "col_2", "col_3"])

    assert  %CSV{ name: "dummy",
                  tracker: %Tracker{},
                  columns: ^columns
                } = CSV.create("dummy", source)
  end

  test "stream a CSV dataset" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    csv_dataset = CSV.create("goofy", source)

    assert  [%{"col_4" => "ABC", "col_5" => "def", "col_6" => "123"},
             %{"col_4" => "KLM", "col_5" => "edd", "col_6" => "678"}] =
      CSV.stream(csv_dataset) |> Enum.to_list
  end

  test "syncing dataset with no changes" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    csv_dataset = CSV.create("goofy", source)

    {:ok, synced_dataset} = CSV.sync(csv_dataset)

    assert synced_dataset == csv_dataset
  end

  test "syncing dataset with updated resource with different columns" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    csv_dataset = CSV.create("goofy", source)
    new_tracker = LocalFile.create("test/fixtures/dummy.csv")
      |>Tracker.create(%LocalDir{path: "tmp/"})

    csv_dataset = %{csv_dataset | tracker: new_tracker}

    assert {:error, "no common columns"} = CSV.sync(csv_dataset)
  end

  test "loading the current version of a csv resource" do
    source = LocalFile.create("test/fixtures/goofy.csv")
    csv_dataset = CSV.create("goofy", source)

    assert CSV.load(csv_dataset) == :ok
  end
end
