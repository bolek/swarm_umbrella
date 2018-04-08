defmodule SwarmEngine.Connectors.LocalDirTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.Resource
  alias SwarmEngine.Test

  test "storing resource" do
    store = %LocalDir{path: "/tmp"}
    con = LocalFile.create("test/fixtures/dummy.csv")
    modified_at = Test.FileHelper.modified_at("test/fixtures/dummy.csv")

    resource = LocalFile.metadata!(con)

    assert {:ok,
            %Resource{
              name: "dummy.csv",
              size: 30,
              modified_at: ^modified_at,
              source: %LocalFile{path: path}
            }} = LocalDir.store(resource, store)

    assert String.starts_with?(path, "/tmp/#{Date.to_iso8601(Date.utc_today(), :basic)}")
    assert File.read("test/fixtures/dummy.csv") == File.read(path)

    File.rm(path)
  end
end
