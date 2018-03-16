defmodule SwarmEngine.Repo.Schema.TrackerTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Repo.Schema.Tracker
  alias SwarmEngine.Connectors.LocalDir

  test "valid changeset" do
    changeset = Tracker.changeset(%Tracker{store: %LocalDir{path: "/tmp"}}, %{
      "source" => %{"type" => "LocalFile", "path" => "some/path"}
    })

    assert changeset.valid?
  end

  test "changeset is invalid if invalid source provided" do
    changeset = Tracker.changeset(%Tracker{store: %LocalDir{path: "/tmp"}}, %{
      "source" => %{"type" => "LocalFile"}
    })

    refute changeset.valid?
  end
end
