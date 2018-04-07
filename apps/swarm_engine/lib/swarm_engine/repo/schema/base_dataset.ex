defmodule SwarmEngine.Repo.Schema.BaseDataset do
  alias __MODULE__

  use SwarmEngine.Schema
  import Ecto.Changeset

  schema "base_datasets" do
    field :name, :string
    field :decoder, SwarmEngine.Repo.Types.Decoder
    field :source, SwarmEngine.Repo.Types.Connector

    timestamps()
  end

  def changeset(%SwarmEngine.DatasetNew{} = dataset) do
    %BaseDataset{}
    |> change(%{
      id: dataset.id,
      name: dataset.name,
      decoder: dataset.decoder,
      source: dataset.source
    })
    |> unique_constraint(:source)
  end
end
