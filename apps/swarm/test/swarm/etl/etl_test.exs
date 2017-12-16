defmodule Swarm.EtlTest do
  use Swarm.DataCase

  alias Swarm.Etl

  describe "datasets" do
    alias Swarm.Etl.Dataset

    @valid_attrs %{name: "some name", decoder: %{}, store: %{}, tracker: %{}}
    @update_attrs %{name: "some updated name", decoder: %{a: 1}, store: %{b: 2}, tracker: %{c: 3}}
    @invalid_attrs %{name: nil, decoder: nil, store: nil, tracker: nil}

    def dataset_fixture(attrs \\ %{}) do
      {:ok, dataset} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Etl.create_dataset()

      dataset
    end

    test "list_datasets/0 returns all datasets" do
      dataset = dataset_fixture()
      assert Etl.list_datasets() == [dataset]
    end

    test "get_dataset!/1 returns the dataset with given id" do
      dataset = dataset_fixture()
      assert Etl.get_dataset!(dataset.id) == dataset
    end

    test "create_dataset/1 with valid data creates a dataset" do
      assert {:ok, %Dataset{} = dataset} = Etl.create_dataset(@valid_attrs)
      assert dataset.name == "some name"
      assert dataset.decoder == %{}
      assert dataset.store == %{}
      assert dataset.tracker == %{}
    end

    test "create_dataset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Etl.create_dataset(@invalid_attrs)
    end

    test "update_dataset/2 with valid data updates the dataset" do
      dataset = dataset_fixture()
      assert {:ok, dataset} = Etl.update_dataset(dataset, @update_attrs)
      assert %Dataset{} = dataset
      assert dataset.name == "some updated name"
      assert dataset.decoder == %{a: 1}
      assert dataset.store == %{b: 2}
      assert dataset.tracker == %{c: 3}
    end

    test "update_dataset/2 with invalid data returns error changeset" do
      dataset = dataset_fixture()
      assert {:error, %Ecto.Changeset{}} = Etl.update_dataset(dataset, @invalid_attrs)
      assert dataset == Etl.get_dataset!(dataset.id)
    end

    test "delete_dataset/1 deletes the dataset" do
      dataset = dataset_fixture()
      assert {:ok, %Dataset{}} = Etl.delete_dataset(dataset)
      assert_raise Ecto.NoResultsError, fn -> Etl.get_dataset!(dataset.id) end
    end

    test "change_dataset/1 returns a dataset changeset" do
      dataset = dataset_fixture()
      assert %Ecto.Changeset{} = Etl.change_dataset(dataset)
    end
  end
end
