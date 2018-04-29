defmodule SwarmEngine.Endpoints.LocalFileTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Endpoints.LocalFile
  alias SwarmEngine.{Connector, Consumer, Resource}
  alias SwarmEngine.Test

  def request(source) do
    source
    |> Consumer.stream()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  test "creating a LocalFile source" do
    assert LocalFile.create("some/path") == %LocalFile{path: "some/path"}
  end

  test "changeset is valid when provided with valid attributes" do
    attrs = %{path: "some_path"}

    changeset = LocalFile.changeset(%LocalFile{}, attrs)

    assert changeset.valid?
  end

  test "changeset is invalid if path not provided" do
    attrs = %{}

    changeset = LocalFile.changeset(%LocalFile{}, attrs)

    assert {:path, {"can't be blank", [validation: :required]}} in changeset.errors
  end

  test "streaming a local file" do
    source = LocalFile.create("test/fixtures/dummy.csv")
    all_elements = Enum.to_list(SwarmEngine.Consumer.stream(source))

    assert [
             %SwarmEngine.Message{
               body: "col_1,col_2,col_3\nABC,def,123\n",
               headers: %{
                 size: 30,
                 resource: %SwarmEngine.Resource{
                   modified_at: ~N[2017-11-17 23:11:33],
                   name: "dummy.csv",
                   size: 30,
                   source: %SwarmEngine.Endpoints.LocalFile{
                     path: "test/fixtures/dummy.csv",
                     type: "LocalFile"
                   }
                 }
               }
             }
           ] = all_elements
  end

  test "metadata happy path" do
    fixture_path = "test/fixtures/test.xlsx"
    source = LocalFile.create(fixture_path)

    expected =
      {:ok,
       %Resource{
         name: "test.xlsx",
         size: 3847,
         source: source,
         modified_at: Test.FileHelper.modified_at(fixture_path)
       }}

    assert expected == Consumer.metadata(source)
  end

  test "metadata for inexisting file" do
    source = LocalFile.create("some_weird_file")

    assert {:error, :enoent} = Consumer.metadata(source)
  end

  test "metadata! - happy path" do
    fixture_path = "test/fixtures/test.xlsx"
    source = LocalFile.create(fixture_path)

    assert %Resource{
             name: "test.xlsx",
             size: 3847,
             source: source,
             modified_at: Test.FileHelper.modified_at(fixture_path)
           } == LocalFile.metadata!(source)
  end

  test "metadata! for inexistent file" do
    source = LocalFile.create("some_weird_file")

    assert_raise RuntimeError, fn -> LocalFile.metadata!(source) end
  end

  test "list resources under given location" do
    location = LocalFile.create("test/fixtures/*")

    assert {:ok,
            [
              %Resource{
                name: "archive.zip",
                modified_at: Test.FileHelper.modified_at("test/fixtures/archive.zip"),
                size: 354,
                source: %LocalFile{path: "test/fixtures/archive.zip"}
              },
              %Resource{
                name: "dummy.csv",
                modified_at: ~N[2017-11-17 23:11:33],
                size: 30,
                source: %LocalFile{path: "test/fixtures/dummy.csv"}
              },
              %Resource{
                name: "goofy.csv",
                modified_at: ~N[2017-11-17 23:11:33],
                size: 42,
                source: %LocalFile{path: "test/fixtures/goofy.csv"}
              },
              %Resource{
                name: "test.xlsx",
                modified_at: ~N[2017-11-17 23:11:33],
                size: 3847,
                source: %LocalFile{path: "test/fixtures/test.xlsx"}
              }
            ]} == Connector.list(location)
  end

  test "list resource under inexisting path" do
    location = LocalFile.create("foo/bar/*")

    assert {:ok, []} = Connector.list(location)
  end

  test "streaming into a local file" do
    endpoint = LocalFile.create("/tmp/output.txt")

    ["abc/n", "def/n"]
    |> Stream.map(fn x -> SwarmEngine.Message.create(x, %{}) end)
    |> SwarmEngine.Producer.into(endpoint)
    |> Stream.run()

    assert File.read!(endpoint.path) == "abc/ndef/n"

    File.rm(endpoint.path)
  end
end
