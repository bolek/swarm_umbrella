defmodule SwarmEngine.DatasetStoreColumn do
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:type, :string)
    field(:original, :string)
  end

  def create(%{name: name, type: type, original: original} = attrs) do
    %DatasetStoreColumn{
      name: name,
      type: type,
      original: original
    }
  end

  def changeset(%DatasetStoreColumn{} = column, attrs) do
    column
    |> cast(attrs, [:name, :type, :original])
    |> validate_required([:name, :type, :original])
  end
end
