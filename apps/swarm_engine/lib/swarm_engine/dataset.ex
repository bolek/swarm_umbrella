defmodule SwarmEngine.Dataset do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias SwarmEngine.{DatasetStore, Decoder, Decoders}

  defstruct [:id, :name, :decoder, :tracker, :store]

  def start_link(%{id: id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(id))
  end

  def init(attrs), do: SwarmEngine.create_dataset(attrs)

  def via_tuple(id), do: {:via, Registry, {Registry.Dataset, id}}

  alias __MODULE__
  alias SwarmEngine.Tracker

  def create2(name, source, decoder \\ Decoders.CSV.create()) do
    {:ok, dataset} = SwarmEngine.DatasetNew.create(name, source, decoder)

    case SwarmEngine.Repo.put_dataset(dataset) do
      {:ok, _} ->
        {:ok, dataset}
      {:error, %{errors: [source: {"has already been taken", []}]}} ->
        {:error, :already_exists}
    end
  end

  def create(name, source, decoder \\ Decoders.CSV.create()) do
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
end
