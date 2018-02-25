defmodule SwarmEngine.TrackerTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.{LocalFile, LocalDir}
  alias SwarmEngine.Tracker

  test "create" do

    assert %Tracker{ source: "source",
              store: "store",
              resources: MapSet.new()
            } == Tracker.create("source", "store")
  end

  test "sync files from source" do
    File.rm("/tmp/fooboo.csv")
    source = %LocalFile{path: "/tmp/fooboo.csv"}
    store = %LocalDir{path: "/tmp"}

    tracker = Tracker.create(source, store)

    tracker = Tracker.sync(tracker)

    assert tracker.resources == MapSet.new()

    # Add new file
    File.write("/tmp/fooboo.csv", "Hello World")
    tracker = Tracker.sync(tracker)

    assert MapSet.size(tracker.resources) == 1

    # change modified date
    File.write_stat("/tmp/fooboo.csv", %{File.stat!("/tmp/fooboo.csv") | mtime: {{2017,1,1},{0,0,0}}})
    tracker = Tracker.sync(tracker)

    assert MapSet.size(tracker.resources) == 2

    # try syncing without any changes
    tracker = Tracker.sync(tracker)
    assert MapSet.size(tracker.resources) == 2

    File.rm("/tmp/fooboo.csv")
  end

  test "current - return current resource based on modified_at" do
    datetime_1 = Timex.now
    datetime_2 = Timex.shift(datetime_1, minutes: 3)

    tracker = %Tracker {
      resources: [%{modified_at: datetime_1}, %{modified_at: datetime_2}]
    }

    assert Tracker.current(tracker) == {:ok, %{modified_at: datetime_2}}

    tracker = %Tracker {
      resources: [%{modified_at: datetime_2}, %{modified_at: datetime_1}]
    }

    assert Tracker.current(tracker) == {:ok, %{modified_at: datetime_2}}
  end

  test "current when no resources" do
    tracker = %Tracker { resources: [] }

    assert Tracker.current(tracker) == {:error, :not_found}
  end

  test "find by version" do
    datetime_1 = Timex.now
    datetime_2 = Timex.shift(datetime_1, minutes: 3)
    datetime_3 = Timex.shift(datetime_1, minutes: 5)

    tracker = %Tracker {
      resources: [%{modified_at: datetime_1}, %{modified_at: datetime_2}]
    }

    assert Tracker.find(tracker, %{version: datetime_1}) == {:ok, %{modified_at: datetime_1}}
    assert Tracker.find(tracker, %{version: datetime_2}) == {:ok, %{modified_at: datetime_2}}
    assert Tracker.find(tracker, %{version: datetime_3}) == {:error, :not_found}
  end

  test "valid changeset" do
    changeset = Tracker.changeset(%Tracker{store: %LocalDir{path: "/tmp"}}, %{
      source: %{type: "LocalFile", args: %{path: "some/path"}}
    })

    assert changeset.valid?
  end
end
