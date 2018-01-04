defmodule SwarmEngine.Resource do
  alias SwarmEngine.{Connector, Resource}

  @type t :: %__MODULE__{
    name: String.t,
    size: integer,
    modified_at: DateTime.t,
    source: Connector.t
  }

  defstruct [:name, :size, :modified_at, :source]

  def from_map(%{"name" => name, "size" => size, "modified_at" => modified_at, "source" => source}) do
    %Resource{
      name: name,
      size: size,
      modified_at: modified_at,
      source: from_map_type(source)
    }
  end

  def from_map(%{} = m) do
    %Resource{
      name: m.name,
      size: m.size,
      modified_at: m.modified_at,
      source: m.source.type.from_map(m.source)
    }
  end

  def from_map_type(%{type: type} = x) do
    type.from_map(x)
  end

  def from_map_type(%{"type" => type} = x) do
    Map.put(x, :type, String.to_existing_atom(type))
    |> from_map_type
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Resource do
  alias SwarmEngine.Resource

  def to_map(%Resource{} = r) do
    %{
      name: r.name,
      size: r.size,
      modified_at: r.modified_at,
      source: SwarmEngine.Mapable.to_map(r.source)
    }
  end
end
