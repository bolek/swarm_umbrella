defmodule SwarmEngine.Datasets.CSV do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias SwarmEngine.{Connector, Dataset}

  def start_link(%{id: id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(id))
  end

  def init(%{name: name, source: source}) do
    {:ok, create(name, source)}
  end

  def via_tuple(id), do: {:via, Registry, {Registry.Dataset, id}}

  alias __MODULE__
  alias SwarmEngine.{Connector, Tracker, Util}
  alias SwarmEngine.Connectors.LocalDir

  defstruct [:name, :tracker, :columns, :dataset]

  def create(name, %Tracker{} = tracker) do
    %CSV{name: name, tracker: tracker, columns: columns(tracker)}
  end

  def create(name, source) do
    tracker = source
    |> Tracker.create(%LocalDir{path: "/tmp/swarm_engine_store/"})
    |> Tracker.sync()

    columns = columns(tracker)
    dataset = %Dataset{
      name: name |> String.downcase() |> String.replace(~r/\s+/, "_"),
      columns: sql_columns(columns)
    }

    Dataset.create(dataset)

    %CSV{
      name: name,
      tracker: tracker,
      columns: columns,
      dataset: dataset
    }
  end

  def stream(%CSV{tracker: tracker}, version) do
    with {:ok, resource} <- Tracker.find(tracker, %{version: version}),
      source <- resource.source
    do
      source
      |> _stream()
    else
      {:error, reason} -> {:error, reason}
      any -> {:error, any}
    end
  end

  def stream(%CSV{tracker: tracker}) do
    tracker
    |> Tracker.current()
    |> get_in([:source])
    |> _stream()
  end

  defp _stream(resource) do
    tmp_file_path = "/tmp/#{Util.UUID.generate}"

    resource
    |> Connector.request
    |> Stream.into(File.stream!(tmp_file_path))
    |> Stream.run

    File.stream!(tmp_file_path)
    |> Util.CSV.decode!(headers: true)
  end

  def sync(%CSV{tracker: tracker, columns: columns} = dataset) do
    tracker = Tracker.sync(tracker)
    new_columns = columns(tracker)

    case MapSet.disjoint?(columns, new_columns) do
      true -> {:error, "no common columns"}
      false -> {:ok, %{dataset | tracker: tracker}}
    end
  end

  def load(%CSV{tracker: tracker} = csv) do
    resource = Tracker.current(tracker)
    _load(csv, resource)
  end

  def load(%CSV{tracker: tracker} = csv, version) do
    resource = Tracker.find(tracker, %{version: version})

    _load(csv, resource)
  end

  defp _load(%CSV{dataset: dataset}, resource) do
    version = resource.modified_at
    stream = _stream(resource.source) |> Stream.map(fn(row) ->
      Enum.map(dataset.columns, &(row[&1.original]))
    end)

    Dataset.insert_stream(dataset, stream, version)
  end

  defp columns(%Tracker{} = tracker) do
    tracker
      |> Tracker.current()
      |> get_in([:source])
      |> columns()
  end

  defp columns(source) do
    source
    |> Connector.request()
    |> Stream.take(1)
    |> Enum.map(&(:binary.split(&1,"\n") |> List.first))
    |> Util.CSV.decode!
    |> Enum.to_list()
    |> List.first()
    |> MapSet.new()
  end

  defp sql_columns(columns) do
    columns
    |> Enum.map(fn c ->
      name = c
      |> String.downcase()
      |> String.replace(~r/\s+/, "_")

      %{name: name, type: "character varying", original: c}
    end)
  end
end
