defmodule SwarmEngine.Dataset do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias SwarmEngine.{DatasetStore, Decoder, Decoders}

  def start_link(%{id: id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(id))
  end

  def init(%{name: name, source: source, decoder: decoder}) do
    dataset = create(name, source, decoder)

    result = dataset
    |> SwarmEngine.Mapable.to_map()
    |> Swarm.Etl.create_dataset()

    IO.inspect(result)

    {:ok, dataset}
  end

  def via_tuple(id), do: {:via, Registry, {Registry.Dataset, id}}

  alias __MODULE__
  alias SwarmEngine.{Tracker}
  alias SwarmEngine.Connectors.LocalDir

  defstruct [:id, :name, :tracker, :columns, :store, decoder: %Decoder{}]

  def create(name, source, decoder \\ Decoder.create(Decoders.CSV.create())) do
    tracker = source
    |> Tracker.create(%LocalDir{path: "/tmp/swarm_engine_store/"})
    |> Tracker.sync()

    with {:ok, cols} <- columns(tracker, decoder),
      store_name <- gen_store_name(name),
      {:ok, store} <- DatasetStore.create(%{name: store_name, columns: cols})
    do
      {:ok, %Dataset{
        id: SwarmEngine.Util.UUID.generate,
        name: name,
        tracker: tracker,
        columns: columns_mapset(store.columns),
        store: store,
        decoder: decoder
      }}
    else
      {:error, e} -> {:error, e}
      any -> {:error, any}
    end
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

  def sync(%Dataset{tracker: tracker, columns: columns, decoder: decoder} = dataset) do
    tracker = Tracker.sync(tracker)
    {:ok, cols} = columns(tracker, decoder)
    new_columns = columns_mapset(cols)

    case MapSet.disjoint?(columns, new_columns) do
      true -> {:error, "no common columns"}
      false -> {:ok, %{dataset | tracker: tracker}}
    end
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

  defp columns_mapset(columns) do
    columns
    |> Enum.map(&(Map.get(&1, :original)))
    |> MapSet.new
  end

  defp columns(%Tracker{} = tracker, decoder) do
    with {:ok, resource} <- Tracker.current(tracker),
      source <- Map.get(resource, :source)
    do
      Decoder.columns(source, decoder)
    else
      {:error, e} -> {:error, e}
    end
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
      tracker: Tracker.from_map(m.tracker),
      columns: columns_mapset(store.columns)
    }
  end

  defp gen_store_name(name), do: name |> String.downcase() |> String.replace(~r/\s+/, "_")
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
