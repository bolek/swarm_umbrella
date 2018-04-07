defmodule SwarmEngineTest do
  use SwarmEngine.DataCase

  doctest SwarmEngine

  test "greets the world" do
    assert SwarmEngine.hello() == :world
  end
end
