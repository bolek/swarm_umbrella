defmodule SwarmEngine.Repo.Schema.Dataset do
  alias SwarmEngine.Repo.Schema

  use SwarmEngine.Schema
  import Ecto.Changeset
  import SwarmEngine.Repo.Changeset.DynamicEmbeds

  schema "datasets" do
    field :name, :string
    field :decoder, SwarmEngine.Repo.Types.Decoder
    has_one :tracker, Schema.Tracker, on_replace: :delete
    embeds_one :store, SwarmEngine.DatasetStore, on_replace: :delete

    timestamps()
  end

  def update_changeset(%Schema.Dataset{} = dataset, attrs) do
    changeset(dataset, attrs)
    |> validate_required([:name, :decoder, :store, :tracker])
  end

  def new_changeset(%Schema.Dataset{} = dataset, attrs) do
    default_tracker = %Schema.Tracker{
      store: %SwarmEngine.Connectors.LocalDir{path: "/tmp"},
      resources: []
    }

    tracker = default_tracker
    |> Schema.Tracker.changeset(attrs)

    changeset(dataset, attrs)
    |> put_assoc(:tracker, tracker)
    |> validate_required([:name, :decoder, :store, :tracker])
  end

  def changeset(%Schema.Dataset{} = dataset, attrs) do
    dataset
    |> cast(attrs, ["name"])
    |> cast_dynamic_embed(:decoder)
    |> put_embed(:store, %SwarmEngine.DatasetStore{name: nil, columns: []})
  end
end
