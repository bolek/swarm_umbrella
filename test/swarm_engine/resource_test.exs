defmodule SwarmEngine.ResourceTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Resource
  alias SwarmEngine.Connectors.LocalFile

  test "creating a resource" do
    assert {:ok, %Resource{name: "dummy"}} =
      Resource.create("dummy")
  end

  test "pulling resource" do
    target = 'test_1'
    {:ok, resource} = Resource.create('dummy')
    source = LocalFile.create('test/fixtures/dummy.csv')

    assert {:ok, [file_path]} =
      Resource.pull(resource, target, source)

    assert {:ok, "col_1,col_2,col_3\nABC,def,123\n"} =
      File.read(file_path)

    # cleanup
    File.rm_rf("tmp/#{resource.id}")
  end

  test "pulling zipped resource" do
    filename = 'test.csv'
    source = LocalFile.create('test/fixtures/archive.zip')

    {:ok, resource} = Resource.create('archive')

    assert {:ok, [file_path_1, file_path_2]} =
      Resource.pull(resource, filename, source)

    assert {:ok, "col_4,col_5,col_6\nABC,def,123\n"} =
      File.read(file_path_1)

    assert {:ok, "col_1,col_2,col_3\nABC,def,123\n"} =
      File.read(file_path_2)

    # cleanup
    File.rm_rf("tmp/#{resource.id}")
  end
end
