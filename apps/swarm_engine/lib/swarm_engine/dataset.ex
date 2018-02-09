defmodule SwarmEngine.Dataset do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias SwarmEngine.{DatasetFactory, DatasetStore, Decoder, Decoders, EctoSimpleStruct}

  def start_link(%{id: id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(id))
  end

  def init(%{name: name, source: source, decoder: decoder}) do
    {:ok, dataset} = DatasetFactory.build(name, source, decoder)

    result = dataset
    |> SwarmEngine.Mapable.to_map()
    |> Swarm.Etl.create_dataset()

    IO.inspect(result)

    {:ok, dataset}
  end

  def via_tuple(id), do: {:via, Registry, {Registry.Dataset, id}}

  alias __MODULE__
  alias SwarmEngine.{Tracker}

  use SwarmEngine.Schema
  import Ecto.Changeset

  schema "datasets" do
    field :name, :string
    field :decoder, EctoSimpleStruct
    has_one :tracker, Tracker
    embeds_one :store, DatasetStore

    timestamps()
  end

  def changeset(%Dataset{} = dataset, attrs) do
    default_tracker = %Tracker{
      store: %SwarmEngine.Connectors.LocalDir{path: "/tmp"},
      resources: []
    }

    tracker = default_tracker
    |> Tracker.changeset(attrs)

    dataset
    |> cast(attrs, [:name, :decoder])
    |> put_assoc(:tracker, tracker)
    |> put_embed(:store, %DatasetStore{name: nil, columns: []})
    |> validate_required([:name, :decoder, :store, :tracker])
  end

  def create(name, source, decoder \\ Decoder.create(Decoders.CSV.create())) do
    SwarmEngine.DatasetFactory.build(name, source, decoder)
  end

  def stream(%Dataset{tracker: tracker, decoder: decoder}, version) do
    with {:ok, resource} <- Tracker.find(tracker, %{version: version})
    do
      resource.source
      |> Decoder.decode!(decoder)
    else
      {:error, reason} -> {:error, reason}
      any -> {:error, any}
    end
  end

  def stream(%Dataset{tracker: tracker, decoder: decoder}) do
    with {:ok, resource} <- Tracker.current(tracker),
      source <- Map.get(resource, :source)
    do
      Decoder.decode!(source, decoder)
    else
      {:error, reason} -> {:error, reason}
      any -> {:error, any}
    end
  end

  def sync(%Dataset{tracker: tracker, store: store, decoder: decoder} = dataset) do
    tracker = Tracker.sync(tracker)
    {:ok, new_columns} = Tracker.current_resource_columns(tracker, decoder)

    case disjoint_columns?(store.columns, new_columns) do
      true -> {:error, "no common columns"}
      false -> {:ok, %{dataset | tracker: tracker}}
    end
  end

  defp disjoint_columns?(current, new) do
    MapSet.disjoint?(
      original_column_mapset(current),
      original_column_mapset(new)
    )
  end

  defp original_column_mapset(columns) do
    columns
    |> Enum.map(&(Map.get(&1, :original)))
    |> MapSet.new
  end

  def load(%Dataset{tracker: tracker} = csv) do
    with {:ok, resource} <- Tracker.current(tracker)
    do
      _load(csv, resource)
    else
      {:error, e} -> {:error, e}
    end
  end

  def load(%Dataset{tracker: tracker} = csv, version) do
    {:ok, resource} = Tracker.find(tracker, %{version: version})

    _load(csv, resource)
  end

  defp _load(%Dataset{store: store, decoder: decoder}, resource) do
    version = resource.modified_at
    stream = Decoder.decode!(resource.source, decoder) |> Stream.map(fn(row) ->
      Enum.map(store.columns, &(row[&1.original]))
    end)

    DatasetStore.insert_stream(store, stream, version)
  end

  def from_map(%{"id" => id, "name" => name, "decoder" => decoder, "store" => store, "tracker" => tracker}) do
    from_map(%{id: id, name: name, decoder: decoder, store: store, tracker: tracker})
  end

  def from_map(%{} = m) do
    store = DatasetStore.from_map(m.store)
    %Dataset{
      id: m.id,
      name: m.name,
      decoder: Decoder.from_map(m.decoder),
      store: store,
      tracker: Tracker.from_map(m.tracker)
    }
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Dataset do
  alias SwarmEngine.Dataset
  def to_map(%Dataset{} = d) do
    %{
      id: d.id,
      name: d.name,
      decoder: SwarmEngine.Mapable.to_map(d.decoder),
      store: SwarmEngine.Mapable.to_map(d.store),
      tracker: SwarmEngine.Mapable.to_map(d.tracker)
    }
  end
end
