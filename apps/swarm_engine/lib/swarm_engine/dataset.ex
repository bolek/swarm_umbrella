defmodule SwarmEngine.Dataset do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias SwarmEngine.{DatasetStore, Decoder, Decoders}

  def start_link(%{id: id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(id))
  end

  def init(%{name: name, source: source, decoder: decoder}) do
    dataset = create(name, source, decoder)

    dataset
    |> SwarmEngine.Persistence.Dataset.serialize()
    |> Swarm.Etl.create_dataset()

    {:ok, dataset}
  end

  def via_tuple(id), do: {:via, Registry, {Registry.Dataset, id}}

  alias __MODULE__
  alias SwarmEngine.{Tracker}
  alias SwarmEngine.Connectors.LocalDir

  defstruct [:name, :tracker, :columns, :store, :decoder]

  def create(name, source, decoder \\ Decoders.CSV.create()) do
    tracker = source
    |> Tracker.create(%LocalDir{path: "/tmp/swarm_engine_store/"})
    |> Tracker.sync()

    cols = columns(tracker, decoder)

    store = %DatasetStore{
      name: name |> String.downcase() |> String.replace(~r/\s+/, "_"),
      columns: cols
    }

    DatasetStore.create(store)

    %Dataset{
      name: name,
      tracker: tracker,
      columns: columns_mapset(cols),
      store: store,
      decoder: decoder
    }
  end

  def stream(%Dataset{tracker: tracker, decoder: decoder}, version) do
    with {:ok, resource} <- Tracker.find(tracker, %{version: version}),
      source <- resource.source
    do
      source
      |> Decoder.decode!(decoder)
    else
      {:error, reason} -> {:error, reason}
      any -> {:error, any}
    end
  end

  def stream(%Dataset{tracker: tracker, decoder: decoder}) do
    tracker
    |> Tracker.current()
    |> Map.get(:source)
    |> Decoder.decode!(decoder)
  end

  def sync(%Dataset{tracker: tracker, columns: columns, decoder: decoder} = dataset) do
    tracker = Tracker.sync(tracker)
    new_columns = columns_mapset(columns(tracker, decoder))

    case MapSet.disjoint?(columns, new_columns) do
      true -> {:error, "no common columns"}
      false -> {:ok, %{dataset | tracker: tracker}}
    end
  end

  def load(%Dataset{tracker: tracker} = csv) do
    resource = Tracker.current(tracker)
    _load(csv, resource)
  end

  def load(%Dataset{tracker: tracker} = csv, version) do
    resource = Tracker.find(tracker, %{version: version})

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
    tracker
      |> Tracker.current()
      |> Map.get(:source)
      |> Decoder.columns(decoder)
  end
end
