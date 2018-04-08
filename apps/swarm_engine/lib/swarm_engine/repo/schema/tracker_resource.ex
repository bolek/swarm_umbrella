defmodule SwarmEngine.Repo.Schema.TrackerResource do
  use SwarmEngine.Schema
  import Ecto.Changeset
  import SwarmEngine.Repo.Changeset.DynamicEmbeds

  alias __MODULE__

  schema "tracker_resources" do
    field(:name, :string)
    field(:size, :integer)
    field(:modified_at, :naive_datetime)
    field(:source, SwarmEngine.Repo.Types.Connector)
    belongs_to(:tracker, SwarmEngine.Repo.Schema.Tracker)

    timestamps()
  end

  def changeset(%TrackerResource{} = record, %SwarmEngine.Resource{} = resource) do
    record
    |> change(%{
      name: resource.name,
      size: resource.size,
      modified_at: resource.modified_at,
      source: resource.source
    })
  end
end
