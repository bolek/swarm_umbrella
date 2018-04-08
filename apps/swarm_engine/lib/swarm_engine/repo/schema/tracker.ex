defmodule SwarmEngine.Repo.Schema.Tracker do
  use SwarmEngine.Schema

  import Ecto.Changeset
  import SwarmEngine.Repo.Changeset.DynamicEmbeds

  alias __MODULE__, as: TrackerSchema
  alias SwarmEngine.Repo.Schema.TrackerResource

  schema "trackers" do
    field(:source, SwarmEngine.Repo.Types.Connector)
    embeds_one(:store, SwarmEngine.Connectors.LocalDir)

    has_many(:resources, SwarmEngine.Repo.Schema.TrackerResource)
    belongs_to(:dataset, SwarmEngine.Repo.Schema.Dataset)

    timestamps()
  end

  def changeset(%TrackerSchema{} = record, %SwarmEngine.Tracker{} = tracker) do
    record
    |> change(%{
      source: tracker.source
    })
    |> put_embed(:store, tracker.store)
    |> put_assoc(:resources, build_resources(tracker.resources))
  end

  def changeset(%TrackerSchema{} = tracker, attrs) do
    tracker
    |> cast(attrs, [])
    |> cast_embed(:store, with: &SwarmEngine.Connectors.LocalDir.changeset/2)
    |> cast_assoc(:resources)
    |> cast_dynamic_embed(:source)
    |> validate_required([:source, :store, :resources])
  end

  defp build_resources(resources) do
    resources
    |> MapSet.to_list()
    |> Enum.map(fn r -> TrackerResource.changeset(%TrackerResource{}, r) end)
  end
end
