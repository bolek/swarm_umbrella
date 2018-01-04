defmodule SwarmEngine.ResourceTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Resource

  test "transforming a resource to a simple map" do
    resource = %Resource{
      name: "Resource",
      size: 12345,
      modified_at: DateTime.utc_now(),
      source: %SwarmEngine.Connectors.LocalFile{path: "some/path", options: []}
    }

    assert SwarmEngine.Mapable.to_map(resource)
      == %{
        name: "Resource",
        size: 12345,
        modified_at: resource.modified_at,
        source: SwarmEngine.Mapable.to_map(resource.source)
      }
  end

  test "creating a resource from a simple map" do
    resource = %Resource{
      name: "Resource",
      size: 12345,
      modified_at: DateTime.utc_now(),
      source: %SwarmEngine.Connectors.LocalFile{path: "some/path", options: []}
    }

    assert (
      resource
      |> SwarmEngine.Mapable.to_map()
      |> Resource.from_map()
    ) == resource
  end
end
