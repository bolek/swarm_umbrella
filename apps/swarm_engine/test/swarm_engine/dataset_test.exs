defmodule SwarmEngine.DatasetTest do
  use SwarmEngine.DataCase

  alias SwarmEngine.Endpoints.{LocalDir, LocalFile, StringIO}
  alias SwarmEngine.{Dataset, DatasetFactory, Tracker}

  @dataset_attrs %{
    name: "goofy",
    source: LocalFile.create("test/fixtures/goofy.csv"),
    decoder: SwarmEngine.Decoders.CSV.create()
  }

  test "init when passing an existing dataset id" do
    {:ok, dataset} = SwarmEngine.DatasetFactory.create(@dataset_attrs)

    assert {:ok, dataset} == Dataset.init(dataset.id)
  end

  test "init when passing an inexistent dataset id" do
    assert {:stop, :not_found} == Dataset.init("ef1ef08e-b02c-4468-9672-f7a546c549f9")
  end

  test "init when passing an invalid dataset id" do
    assert {:stop, :not_found} == Dataset.init("abcd")
  end

  test "stream a dataset" do
    {:ok, dataset} = DatasetFactory.build(@dataset_attrs)

    assert [
             %SwarmEngine.Message{body: %{"col_4" => "ABC", "col_5" => "def", "col_6" => "123"}},
             %SwarmEngine.Message{body: %{"col_4" => "KLM", "col_5" => "edd", "col_6" => "678"}}
           ] = Dataset.stream(dataset) |> Enum.to_list()
  end

  test "syncing dataset with no changes" do
    {:ok, dataset} = DatasetFactory.build(@dataset_attrs)

    {:ok, synced_dataset} = Dataset.sync(dataset)

    assert synced_dataset == dataset
  end

  test "syncing dataset with updated resource with different columns" do
    source = StringIO.create("bunny", "col_4,col_5,col_6\nABC,def,123\nKLM,edd,678")

    {:ok, dataset} =
      DatasetFactory.build(%{
        name: "goofy",
        decoder: SwarmEngine.Decoders.CSV.create(),
        source: source
      })

    new_tracker =
      LocalFile.create("test/fixtures/dummy.csv")
      |> Tracker.create(%LocalDir{path: "tmp/"})

    dataset = %{dataset | tracker: new_tracker}

    assert {:error, "no common columns"} = Dataset.sync(dataset)
  end

  test "loading the current version of a csv resource" do
    source = StringIO.create("honey", "col_4,col_5,col_6\nABC,def,123\nKLM,edd,678")

    {:ok, dataset} =
      DatasetFactory.build(%{
        name: "goofy",
        decoder: SwarmEngine.Decoders.CSV.create(),
        source: source
      })

    assert Dataset.load(dataset) == :ok
  end
end
