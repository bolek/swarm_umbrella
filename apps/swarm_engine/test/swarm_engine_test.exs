defmodule SwarmEngineTest do
  use SwarmEngine.DataCase

  doctest SwarmEngine

  test "greets the world" do
    assert SwarmEngine.hello() == :world
  end

  @valid_attrs %{
    name: "My Dataset",
    source: %{
      type: "Elixir.SwarmEngine.Connectors.LocalFile",
      args: %{path: "tmp.txt"}
    },
    decoder: %{
      type: "Elixir.SwarmEngine.Decoders.CSV",
      args: %{headers: true, separator: ",", delimiter: "/n"}
    }
  }

  alias SwarmEngine.Dataset

  def dataset_fixture(attrs \\ %{}) do
    {:ok, dataset} =
      attrs
      |> Enum.into(@valid_attrs)
      |> SwarmEngine.create_dataset

    dataset
  end

  test "create_dataset/1 with valid data creates a dataset" do
    assert {:ok, %Dataset{}} = SwarmEngine.create_dataset(@valid_attrs)
  end

  test "get_dataset/1 returns dataset with given id" do
    dataset = dataset_fixture()
    assert SwarmEngine.get_dataset!(dataset.id) == dataset
  end

  test "list_datasets/0 returns empty array when no datasets" do
    assert SwarmEngine.list_datasets() == []
  end

  test "list_datasets/0 returns list of existing datasets" do
    dataset_1 = dataset_fixture()
    dataset_2 = dataset_fixture()
    assert SwarmEngine.list_datasets() == [dataset_1, dataset_2]
  end
end
