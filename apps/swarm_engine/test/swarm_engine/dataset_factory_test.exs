defmodule SwarmEngine.DatasetFactoryTest do
  use SwarmEngine.DataCase

  alias SwarmEngine.DatasetFactory
  alias SwarmEngine.Connectors.LocalFile
  alias SwarmEngine.Connectors.StringIO
  alias SwarmEngine.{DatasetStore, Tracker}

  test "build_async returns a valid DatasetNew struct" do
    source = StringIO.create("goofy", "col_4,col_5,col_6\nABC,def,123\nKLM,edd,999")
    decoder = SwarmEngine.Decoders.CSV.create()
    {:ok, dataset, _} = DatasetFactory.build_async("goofy", source)

    assert %SwarmEngine.DatasetNew{id: dataset.id, name: "goofy", source: source, decoder: decoder}
      == dataset
  end

  test "build_async returns error when creating an existing dataset with source" do
    source = LocalFile.create("test/fixtures/dummy.csv")
    {:ok, _, _} = DatasetFactory.build_async("goofy", source)

    assert {:error, _} = DatasetFactory.build_async("goofy", source)
  end

  test "build_async initialized a dataset asynchronously" do
    source = StringIO.create("list", "col_4,col_5,col_6\nABC,def,123\nKLM,edd,980")

    {:ok, _, task} = DatasetFactory.build_async("goofy", source)

    assert {:ok, %SwarmEngine.Dataset{}} = Task.await(task)
  end

  test "creating a dataset by providing name and source" do
    source = LocalFile.create("test/fixtures/dummy.csv")

    assert  {:ok, %SwarmEngine.Dataset{ name: "dummy",
                  tracker: %Tracker{},
                  store: %DatasetStore{
                    name: _,
                    columns: [%{
                      name: "col_1",
                      type: "character varying",
                      original: "col_1"
                    }, %{
                      name: "col_2",
                      type: "character varying",
                      original: "col_2"
                    }, %{
                      name: "col_3",
                      type: "character varying",
                      original: "col_3"
                    }]
                  }
                }} = DatasetFactory.build("dummy", source)
  end

  test "creating a dataset by providing name and an inexistent source" do
    source = LocalFile.create("test/fixtures/fooooooo.csv")

    assert {:error, :not_found} = DatasetFactory.build("dummy", source)
  end
end
