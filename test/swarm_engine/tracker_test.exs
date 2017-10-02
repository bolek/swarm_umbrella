defmodule SwarmEngine.TrackerTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.LocalFile
  alias SwarmEngine.Tracker

  test "create" do

    assert %Tracker{ source: "source",
              store: "store",
              resources: MapSet.new()
            } == Tracker.create("source", "store")
  end

  test "sync files from source" do
    File.rm("/tmp/fooboo.csv")
    source = LocalFile.create(%{path: "/tmp/fooboo.csv"})
    store = LocalFile.create(%{base_path: "/tmp"})

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
end
