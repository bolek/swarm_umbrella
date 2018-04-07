defmodule SwarmEngine.Repo.Schema.BaseDataset do
  alias __MODULE__

  use SwarmEngine.Schema
  import Ecto.Changeset

  schema "base_datasets" do
    field(:name, :string)
    field(:decoder, SwarmEngine.Repo.Types.Decoder)
    field(:source, SwarmEngine.Repo.Types.Connector)
    field(:status, SwarmEngine.Repo.Schema.DatasetStatus)

    timestamps()
  end

  def changeset(%SwarmEngine.DatasetNew{} = dataset) do
    %BaseDataset{}
    |> change(%{
      id: dataset.id,
      name: dataset.name,
      decoder: dataset.decoder,
      source: dataset.source,
      status: :new
    })
    |> unique_constraint(:source)
    |> unique_constraint(:id, name: :base_datasets_pkey)
  end
end
