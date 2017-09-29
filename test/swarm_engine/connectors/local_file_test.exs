defmodule SwarmEngine.Connectors.LocalFileTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connectors.LocalFile

  def request(source) do
    source
    |> LocalFile.request()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  test "creating a LocalFile source" do
    assert LocalFile.create(%{path: "some/path"}) ==
      {LocalFile, %{path: "some/path"}, []}
  end

  test "streaming a local file" do
    source = LocalFile.create(%{path: "test/fixtures/dummy.csv"})

    assert "col_1,col_2,col_3\nABC,def,123\n" ==
      LocalFileTest.request(source)
  end

  test "metadata happy path" do
    source = LocalFile.create(%{path: "test/fixtures/test.xlsx"})

    expected = {:ok, %{filename: "test.xlsx",
                       size: 3847,
                       source: source,
                       modified_at: %DateTime{year: 2017, month: 9, day: 24, hour: 14, minute: 51, second: 13,
                                              time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0}
                      }
                }

    assert expected == LocalFile.metadata(source)
  end

  test "metadata for inexisting file" do
    source = LocalFile.create(%{path: "some_weird_file"})

    assert {:error, :enoent} = LocalFile.metadata(source)
  end

  test "metadata! - happy path" do
    source = LocalFile.create(%{path: "test/fixtures/test.xlsx"})

    assert %{ filename: "test.xlsx",
                size: 3847,
                source: source,
                modified_at: %DateTime{year: 2017, month: 9, day: 24, hour: 14, minute: 51, second: 13,
                                       time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0}
            } == LocalFile.metadata!(source)
  end

  test "metadata! for inexsting file" do
    source = LocalFile.create(%{path: "some_weird_file"})

    assert_raise RuntimeError, fn -> LocalFile.metadata!(source) end
  end

  test "storing a resource in a new location" do
    source = LocalFile.create(%{path: "test/fixtures/dummy.csv"})
    {:ok, resource} = LocalFile.metadata(source)

    target = LocalFile.create(%{path: "/tmp/dummy2.csv"})

    expected = {:ok, %{ filename: "dummy.csv",
                        size: 30,
                        source: target,
                        modified_at: %DateTime{
                          year: 2017, month: 9, day: 24,
                          hour: 5, minute: 43, second: 40,
                          time_zone: "Etc/UTC", zone_abbr: "UTC",
                          utc_offset: 0, std_offset: 0
                        }
                      }
                }

    assert expected == LocalFile.store(resource, target)

    assert File.read("test/fixtures/dummy.csv") == File.read("/tmp/dummy2.csv")

    # cleanup
    File.rm("/tmp/dummy2.csv")
  end

  test "storing a stream in a new location" do
    target = LocalFile.create(%{path: "/tmp/stream2.csv"})

    result = ["col1,col2,col13\n", "123,234,345\n"]
    |> Stream.map(&(&1))
    |> LocalFile.store_stream(target)

    assert {:ok, %{ filename: "stream2.csv",
                    size: 28,
                    source: {LocalFile, %{path: "/tmp/stream2.csv"}, []},
                    modified_at: %DateTime{},
                  }
            } = result

    # cleanup
    File.rm("/tmp/stream2.csv")
  end

  test "list resouces under given location" do
    location = LocalFile.create(%{path: "test/fixtures/*"})

    assert {:ok, [
      %{filename: "archive.zip", modified_at: %DateTime{}, size: 354, source: {SwarmEngine.Connectors.LocalFile, %{path: "test/fixtures/archive.zip"}, []}},
      %{filename: "dummy.csv", modified_at: %DateTime{}, size: 30, source: {SwarmEngine.Connectors.LocalFile, %{path: "test/fixtures/dummy.csv"}, []}},
      %{filename: "test.xlsx", modified_at: %DateTime{}, size: 3847, source: {SwarmEngine.Connectors.LocalFile, %{path: "test/fixtures/test.xlsx"}, []}}
    ]} = LocalFile.list(location)
  end
end
