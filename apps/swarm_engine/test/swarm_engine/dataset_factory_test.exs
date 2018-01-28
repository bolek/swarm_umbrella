defmodule SwarmEngine.DatasetFactoryTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.DatasetFactory
  alias SwarmEngine.Connectors.LocalFile
  alias SwarmEngine.{Dataset, DatasetStore, DataVault, Tracker}

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DataVault)
  end

  test "creating a dataset by providing name and source" do
    source = LocalFile.create("test/fixtures/dummy.csv")

    assert  {:ok, %Dataset{ name: "dummy",
                  tracker: %Tracker{},
                  store: %DatasetStore{
                    name: "dummy",
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
