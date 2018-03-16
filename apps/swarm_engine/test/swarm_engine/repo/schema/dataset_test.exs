defmodule SwarmEngine.Repo.Schema.DatasetTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Repo.Schema.Dataset


  test "changeset is valid when provided with valid attributes" do
    attrs = %{
      name: "test",
      source: %{type: "LocalFile", path: "tmp.csv"},
      decoder: %{type: "CSV", headers: true, separator: ",", delimiter: "/n" }
    }

    changeset = Dataset.new_changeset(%Dataset{}, attrs)

    assert changeset.valid?
  end

  test "changeset is invalid if decoder not provided" do
    attrs = %{}

    changeset = Dataset.new_changeset(%Dataset{}, attrs)

    assert {:decoder, {"can't be blank", [validation: :required]}} in changeset.errors
  end

  test "changeset is invalid if name not provided" do
    attrs = %{}

    changeset = Dataset.new_changeset(%Dataset{}, attrs)

    assert {:name, {"can't be blank", [validation: :required]}} in changeset.errors
  end

  test "changeset is invalid if source not provided" do
    attrs = %{
      name: "test",
      decoder: %{type: "CSV", args: %{headers: true, separator: ",", delimiter: "/n"} }
    }

    changeset = Dataset.new_changeset(%Dataset{}, attrs)

    assert {:source, {"can't be blank", [validation: :required]}} in changeset.changes.tracker.errors
  end

  test "changeset is invalid if invalid decoder provided" do
    attrs = %{
      source: %{type: "LocalFile", args: %{path: "tmp.csv"}},
      decoder: %{headers: true, separator: ",", delimiter: "/n"}
    }

    changeset = Dataset.new_changeset(%Dataset{}, attrs)

    assert {:decoder, {"have unknown type", [inclusion: ["CSV"], validation: :inclusion]}} in changeset.errors
  end
end
