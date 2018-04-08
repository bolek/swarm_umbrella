defmodule SwarmEngine.DatasetNewTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.DatasetNew

  doctest SwarmEngine.DatasetNew

  @valid_changeset_attrs %{
    "decoder" => %{
      "delimiter" => "/n",
      "headers" => true,
      "separator" => ",",
      "type" => "CSV"
    },
    "name" => "My Dataset",
    "source" => %{"path" => "tmp.txt", "type" => "LocalFile"}
  }

  test "changeset given valid attributes" do
    changeset = DatasetNew.changeset(%DatasetNew{}, @valid_changeset_attrs)

    assert changeset.valid?
  end

  test "changeset is invalid if required attrs not provided" do
    attrs = %{}

    changeset = DatasetNew.changeset(%DatasetNew{}, attrs)

    assert {:decoder, {"can't be blank", [validation: :required]}} in changeset.errors
    assert {:name, {"can't be blank", [validation: :required]}} in changeset.errors
    assert {:source, {"can't be blank", [validation: :required]}} in changeset.errors
  end
end
