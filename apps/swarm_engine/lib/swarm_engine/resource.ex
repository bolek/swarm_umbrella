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
end
