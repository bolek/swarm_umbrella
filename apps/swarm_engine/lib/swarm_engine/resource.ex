defmodule SwarmEngine.Resource do
  alias SwarmEngine.{Connector, Resource}

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :size, :integer
    field :modified_at, :utc_datetime
    embeds_one :source, Connector
  end

  def changeset(%Resource{} = resource, attrs) do
    resource
    |> cast(attrs, [:name, :size, :modified_at, :source])
    |> validate_required([:name, :size, :modified_at, :source])
  end

  def from_map(%{"name" => name, "size" => size, "modified_at" => modified_at, "source" => source}) do
    %Resource{
      name: name,
      size: size,
      modified_at: modified_at,
      source: Connector.from_map(source)
    }
  end

  def from_map(%{} = m) do
    %Resource{
      name: m.name,
      size: m.size,
      modified_at: m.modified_at,
      source: Connector.from_map(m.source)
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
