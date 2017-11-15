defmodule SwarmEngine.Util.ZipTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Util.Zip

  test "detecting zip file" do
    assert Zip.zipped?('test/fixtures/archive.zip')
    refute Zip.zipped?('test/fixtures/dummy.csv')
  end
end
