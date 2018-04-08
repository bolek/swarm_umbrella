defmodule SwarmEngine.Repo.Schema.Dataset do
  use SwarmEngine.Schema
  import Ecto.Changeset

  alias __MODULE__, as: DatasetSchema
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

  def changeset(%DatasetSchema{} = record, %SwarmEngine.DatasetNew{} = dataset) do
    record
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

  def changeset(%DatasetSchema{} = record, %SwarmEngine.Dataset{
        store: store,
        tracker: tracker
      }) do
    record
    |> change()
    |> put_assoc(:tracker, Schema.Tracker.changeset(%Schema.Tracker{}, tracker))
    |> put_change(:status, :active)
    |> put_embed(:store, store)
  end
end
