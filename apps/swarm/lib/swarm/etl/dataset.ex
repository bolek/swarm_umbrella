defmodule Swarm.Etl.Dataset do
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Etl.Dataset


  schema "datasets" do
    field :name, :string
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(%Dataset{} = dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :url])
    |> validate_required([:name, :url])
  end
end
