defmodule SwarmEngine.EctoSimpleStructTest do
  use ExUnit.Case, async: true
  use SwarmEngine.EctoSimpleStruct, namespace: SwarmEngine

  alias __MODULE__

  defstruct [:foo, :bar]

  @valid_map %{type: "EctoSimpleStructTest", args: %{foo: "ha", bar: "ga"}}
  def valid_struct, do: %EctoSimpleStructTest{foo: "ha", bar: "ga"}


  test "cast/1 given a struct" do
    assert {:ok, valid_struct()} == EctoSimpleStructTest.cast(valid_struct())
  end

  test "cast/1 given a valid map" do
    assert {:ok, valid_struct()} == EctoSimpleStructTest.cast(@valid_map)
  end

  test "cast/1 given an invalid map" do
    assert :error == EctoSimpleStructTest.cast(%{a: 1, b: 2})
  end

  test "dump/1 given valid struct" do
    assert {:ok, %{type: "EctoSimpleStructTest", args: %{foo: "ha", bar: "ga"}}}
      == EctoSimpleStructTest.dump(valid_struct())
  end

  test "dump/1 given map" do
    assert :error == EctoSimpleStructTest.dump(%{a: 1, b: 2})
  end
end
