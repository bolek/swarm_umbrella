defmodule SwarmEngine.DatasetNew do
  alias __MODULE__

  # @enforce_keys [:id, :name, :decoder, :source]
  # defstruct [:id, :name, :decoder, :source]

  use SwarmEngine.Schema
  import Ecto.Changeset
  import SwarmEngine.Repo.Changeset.DynamicEmbeds

  embedded_schema do
    field(:name, :string)
    field(:decoder, SwarmEngine.Repo.Types.Decoder)
    field(:source, SwarmEngine.Repo.Types.Endpoint)
  end

  def create(%{name: name, source: source} = attrs) do
    {:ok,
     %DatasetNew{
       id: Map.get(attrs, :id, SwarmEngine.Util.UUID.generate()),
       name: name,
       source: source,
       decoder: Map.get(attrs, :decoder, SwarmEngine.Decoders.CSV.create())
     }}
  end

  def create_changeset(%{} = attrs) do
    %DatasetNew{}
    |> changeset(attrs)
  end

  def changeset(%DatasetNew{} = dataset, %{} = %DatasetNew{} = new) do
    dataset
    |> change(Map.from_struct(new))
  end

  def changeset(%DatasetNew{} = dataset, %{} = attrs) do
    dataset
    |> cast(attrs, ~w(id name))
    |> cast_dynamic_embed(:decoder)
    |> cast_dynamic_embed(:source)
    |> validate_required(~w(name decoder source)a)
  end
end
