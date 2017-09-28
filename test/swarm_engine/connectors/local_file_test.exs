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

  test "retrieving metadata" do
    source = LocalFile.create(%{path: "test/fixtures/test.xlsx"})

    expected = {:ok, %{filename: "test.xlsx",
                       size: 3847,
                       source: source,
                       modified_at: %DateTime{year: 2017, month: 9, day: 24, hour: 14, minute: 51, second: 13,
                                              time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0}
                      }
                }

    assert expected == LocalFile.request_metadata(source)
  end
end
