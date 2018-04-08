defmodule SwarmEngine.Repo.Schema.Tracker do
  alias __MODULE__

  use SwarmEngine.Schema

  import Ecto.Changeset
  import SwarmEngine.Repo.Changeset.DynamicEmbeds

  schema "trackers" do
    field(:source, SwarmEngine.Repo.Types.Connector)
    embeds_one(:store, SwarmEngine.Connectors.LocalDir)
    embeds_many(:resources, SwarmEngine.Resource)
    # belongs_to :dataset, SwarmEngine.Repo.Schema.Dataset

    timestamps()
  end

  def changeset(%Tracker{} = tracker, attrs) do
    tracker
    |> cast(attrs, [])
    |> cast_embed(:store, with: &SwarmEngine.Connectors.LocalDir.changeset/2)
    |> cast_embed(:resources, with: &SwarmEngine.Resource.changeset/2)
    |> cast_dynamic_embed(:source)
    |> validate_required([:source, :store, :resources])
  end
end
