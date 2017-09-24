defmodule SwarmEngine.Connectors.LocalFileTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connectors.LocalFile

  def get(params) do
    LocalFile.get(params)
      |> Enum.to_list()
      |> Enum.join(" ")
  end

  test "streaming a local file" do
    assert "col_1,col_2,col_3\nABC,def,123\n" =
      LocalFileTest.get(%{path: "test/fixtures/dummy.csv"})
  end
end
