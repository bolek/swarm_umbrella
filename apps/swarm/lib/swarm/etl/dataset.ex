defmodule Swarm.Etl.Dataset do
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Etl.Dataset

  @derive {Poison.Encoder, only: [:name, :decoder, :store, :tracker]}

  schema "datasets" do
    field :name, :string
    field :decoder, :map
    field :store, :map
    field :tracker, :map
    timestamps()
  end

  @doc false
  def changeset(%Dataset{} = dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :decoder, :store, :tracker])
    |> validate_required([:name, :decoder, :store, :tracker])
  end
end
