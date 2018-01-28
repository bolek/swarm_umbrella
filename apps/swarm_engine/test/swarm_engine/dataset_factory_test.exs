defmodule SwarmEngine.DatasetFactoryTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.DatasetFactory
  alias SwarmEngine.Connectors.LocalFile
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
                }} = DatasetFactory.build("dummy", source)
  end

  test "creating a dataset by providing name and an inexistent source" do
    source = LocalFile.create("test/fixtures/fooooooo.csv")

    assert {:error, :not_found} = DatasetFactory.build("dummy", source)
  end
end
