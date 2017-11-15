defmodule SwarmEngineTest do
  use ExUnit.Case
  doctest SwarmEngine

  test "greets the world" do
    assert SwarmEngine.hello() == :world
  end
end
