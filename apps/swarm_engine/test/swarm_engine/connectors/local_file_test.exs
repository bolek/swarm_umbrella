defmodule SwarmEngine.Connectors.LocalFileTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connectors.LocalFile
  alias SwarmEngine.{Connector, Resource}

  def request(source) do
    source
    |> Connector.request()
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

    assert "col_1,col_2,col_3\nABC,def,123\n" == LocalFileTest.request(source)
  end

  test "metadata happy path" do
    fixture_path = "test/fixtures/test.xlsx"
    source = LocalFile.create(fixture_path)
    {{y, m, d}, {h, min, s}} = File.stat!(fixture_path).mtime

    expected =
      {:ok,
       %Resource{
         name: "test.xlsx",
         size: 3847,
         source: source,
         modified_at: %DateTime{
           year: y,
           month: m,
           day: d,
           hour: h,
           minute: min,
           second: s,
           time_zone: "Etc/UTC",
           zone_abbr: "UTC",
           utc_offset: 0,
           std_offset: 0,
           microsecond: {0, 6}
         }
       }}

    assert expected == Connector.metadata(source)
  end

  test "metadata for inexisting file" do
    source = LocalFile.create("some_weird_file")

    assert {:error, :enoent} = Connector.metadata(source)
  end

  test "metadata! - happy path" do
    fixture_path = "test/fixtures/test.xlsx"
    source = LocalFile.create(fixture_path)
    {{y, m, d}, {h, min, s}} = File.stat!(fixture_path).mtime

    assert %Resource{
             name: "test.xlsx",
             size: 3847,
             source: source,
             modified_at: %DateTime{
               year: y,
               month: m,
               day: d,
               hour: h,
               minute: min,
               second: s,
               time_zone: "Etc/UTC",
               zone_abbr: "UTC",
               utc_offset: 0,
               std_offset: 0,
               microsecond: {0, 6}
             }
           } == LocalFile.metadata!(source)
  end

  test "metadata! for inexsting file" do
    source = LocalFile.create("some_weird_file")

    assert_raise RuntimeError, fn -> LocalFile.metadata!(source) end
  end

  test "storing a resource in a new location" do
    fixture_path = "test/fixtures/dummy.csv"
    source = LocalFile.create(fixture_path)
    {{y, m, d}, {h, min, s}} = File.stat!(fixture_path).mtime

    {:ok, resource} = Connector.metadata(source)

    target = LocalFile.create("/tmp/dummy2.csv")

    expected =
      {:ok,
       %Resource{
         name: "dummy.csv",
         size: 30,
         source: target,
         modified_at: %DateTime{
           year: y,
           month: m,
           day: d,
           hour: h,
           minute: min,
           second: s,
           time_zone: "Etc/UTC",
           zone_abbr: "UTC",
           utc_offset: 0,
           std_offset: 0,
           microsecond: {0, 6}
         }
       }}

    assert expected == LocalFile.store(resource, target)

    assert File.read("test/fixtures/dummy.csv") == File.read("/tmp/dummy2.csv")

    # cleanup
    File.rm("/tmp/dummy2.csv")
  end

  test "storing a stream in a new location" do
    target = LocalFile.create("/tmp/stream2.csv")

    result =
      ["col1,col2,col13\n", "123,234,345\n"]
      |> Stream.map(& &1)
      |> LocalFile.store_stream(target)

    assert {:ok,
            %Resource{
              name: "stream2.csv",
              size: 28,
              source: %LocalFile{path: "/tmp/stream2.csv"},
              modified_at: %DateTime{}
            }} = result

    # cleanup
    File.rm("/tmp/stream2.csv")
  end

  test "list resources under given location" do
    location = LocalFile.create("test/fixtures/*")

    assert {:ok,
            [
              %Resource{
                name: "archive.zip",
                modified_at: %DateTime{},
                size: 354,
                source: %LocalFile{path: "test/fixtures/archive.zip"}
              },
              %Resource{
                name: "dummy.csv",
                modified_at: %DateTime{},
                size: 30,
                source: %LocalFile{path: "test/fixtures/dummy.csv"}
              },
              %Resource{
                name: "goofy.csv",
                modified_at: %DateTime{},
                size: 42,
                source: %LocalFile{path: "test/fixtures/goofy.csv"}
              },
              %Resource{
                name: "test.xlsx",
                modified_at: %DateTime{},
                size: 3847,
                source: %LocalFile{path: "test/fixtures/test.xlsx"}
              }
            ]} = Connector.list(location)
  end

  test "list resource under inexisting path" do
    location = LocalFile.create("foo/bar/*")

    assert {:ok, []} = Connector.list(location)
  end
end
