  defmodule SwarmEngine.Tracker do
  alias SwarmEngine.{Connector, Dataset, EctoSimpleStruct, DatasetStore, Decoder, Tracker, Resource}
  alias SwarmEngine.Connectors.LocalDir

  use SwarmEngine.Schema
  import Ecto.Changeset

  schema "trackers" do
    field :source, EctoSimpleStruct
    embeds_one :store, LocalDir
    embeds_many :resources, Resource
    belongs_to :dataset, Dataset

    timestamps()
  end

  def changeset(%Tracker{}=tracker, attrs) do
    tracker
    |> cast(attrs, [:source])
    |> cast_embed(:store, with: &LocalDir.changeset/2)
    |> cast_embed(:resources, with: &Resource.changeset/2)
    |> validate_required([:source, :store, :resources])
  end

  def create(source, store) do
    %Tracker{source: source, store: store, resources: MapSet.new()}
  end

  def synced?(tracker, resource) do
    find(tracker, resource) != nil
  end

  def find(tracker, %{name: name, size: size, modified_at: modified_at}) do
    tracker.resources
    |> Enum.find(fn(x) ->
                    x.name == name
                    && x.size == size
                    && x.modified_at == modified_at
                 end
                )
  end

  def find(tracker, %{version: version}) do
    case tracker.resources |> Enum.find(&(&1.modified_at == version)) do
      nil -> {:error, :not_found}
      resource -> {:ok, resource}
    end
  end

  def sync(%Tracker{source: source} = tracker) do
    {:ok, resources} = Connector.list(source)

    resources
    |> Enum.reduce(tracker, fn(x, tracker) ->
                              Tracker.add(tracker, x)
                            end)
  end

  def current(%Tracker{resources: resources}) do
    case Enum.max_by(resources, fn(x) -> Map.get(x, :modified_at) end, fn -> nil end) do
      nil ->
        {:error, :not_found}
      r ->
        {:ok, r}
    end
  end

  def current_resource_columns(%Tracker{} = tracker, decoder) do
    with {:ok, resource} <- Tracker.current(tracker) do
      Decoder.columns(resource.source, decoder)
    else
      {:error, e} -> {:error, e}
    end
  end

  def add(tracker, resource) do
    case Tracker.find(tracker, resource) do
      nil ->
        {:ok, new} = tracker.store.__struct__.store(resource, tracker.store)
        put_in(tracker.resources, MapSet.put(tracker.resources, new))
      _ ->
        tracker
    end
  end
end
