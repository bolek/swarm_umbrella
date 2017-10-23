defmodule SwarmEngine.Connectors.LocalDirTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.{LocalDir, LocalFile}

  test "storing resource" do
    store = %LocalDir{path: "/tmp"}
    con = LocalFile.create("test/fixtures/dummy.csv")
    {{y, m, d}, {h, min, s}} = File.stat!("test/fixtures/dummy.csv").mtime

    resource = LocalFile.metadata!(con)

    assert {:ok, %{filename: "dummy.csv",
                   size: 30,
                   modified_at: %DateTime{
                     year: ^y, month: ^m, day: ^d,
                     hour: ^h, minute: ^min, second: ^s,
                     time_zone: "Etc/UTC", zone_abbr: "UTC",
                     utc_offset: 0, std_offset: 0
                   },
                   source: %LocalFile{path: path, options: []}
            }} = LocalDir.store(resource, store)

    assert String.starts_with?(path, "/tmp/#{Date.to_iso8601(Date.utc_today, :basic)}")
    assert File.read("test/fixtures/dummy.csv") == File.read(path)

    File.rm(path)
  end
end
