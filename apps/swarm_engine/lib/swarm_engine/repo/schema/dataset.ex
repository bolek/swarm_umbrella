defmodule SwarmEngine.Repo.Schema.Dataset do
  use SwarmEngine.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias SwarmEngine.Repo.Schema

  schema "datasets" do
    field(:name, :string)
    field(:decoder, SwarmEngine.Repo.Types.Decoder)
    field(:source, SwarmEngine.Repo.Types.Connector)
    has_one(:tracker, Schema.Tracker, on_replace: :delete)
    embeds_one(:store, SwarmEngine.DatasetStore, on_replace: :delete)
    field(:status, SwarmEngine.Repo.Schema.DatasetStatus)

    timestamps()
  end

  def changeset(%SwarmEngine.DatasetNew{} = dataset) do
    %Dataset{}
    |> change(%{
      id: dataset.id,
      name: dataset.name,
      decoder: dataset.decoder,
      source: dataset.source,
      status: :new
    })
    |> unique_constraint(:source)
    |> unique_constraint(:id, name: :datasets_pkey)
  end
end
