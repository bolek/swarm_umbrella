defmodule SwarmEngine.DatasetFactoryTest do
  use SwarmEngine.DataCase

  alias SwarmEngine.DatasetFactory
  alias SwarmEngine.Endpoints.LocalFile
  alias SwarmEngine.Endpoints.StringIO
  alias SwarmEngine.{DatasetStore, Tracker}

  @valid_attrs %{
    source: StringIO.create("goofy", "col_4,col_5,col_6\nABC,def,123\nKLM,edd,999"),
    decoder: SwarmEngine.Decoders.CSV.create(),
    name: "goofy"
  }

  test "build_async returns a valid DatasetNew struct" do
    {:ok, dataset, _} = DatasetFactory.build_async(@valid_attrs)

    assert %SwarmEngine.DatasetNew{
             id: dataset.id,
             name: @valid_attrs.name,
             source: @valid_attrs.source,
             decoder: @valid_attrs.decoder
           } == dataset
  end

  test "build_async returns error when creating an existing dataset with source" do
    {:ok, _, _} = DatasetFactory.build_async(@valid_attrs)

    assert {:error, _} = DatasetFactory.build_async(@valid_attrs)
  end

  test "build_async initializes a dataset asynchronously" do
    {:ok, _, task} = DatasetFactory.build_async(@valid_attrs)

    assert {:ok, %SwarmEngine.Dataset{}} = Task.await(task)
  end

  test "creating a dataset by providing name and source" do
    assert {:ok,
            %SwarmEngine.Dataset{
              name: "goofy",
              tracker: %Tracker{},
              store: %DatasetStore{
                name: _,
                columns: [
                  %{
                    name: "col_4",
                    type: "character varying",
                    original: "col_4"
                  },
                  %{
                    name: "col_5",
                    type: "character varying",
                    original: "col_5"
                  },
                  %{
                    name: "col_6",
                    type: "character varying",
                    original: "col_6"
                  }
                ]
              }
            }} = DatasetFactory.build(@valid_attrs)
  end

  test "creating a dataset by providing name and an inexistent source" do
    source = LocalFile.create("test/fixtures/fooooooo.csv")

    assert {:error, :not_found} =
             DatasetFactory.build(%{
               name: "dummy",
               source: source,
               decoder: SwarmEngine.Decoders.CSV.create()
             })
  end
end
