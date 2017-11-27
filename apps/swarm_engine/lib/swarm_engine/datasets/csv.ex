defmodule SwarmEngine.Datasets.CSV do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias SwarmEngine.{Connector, Dataset}

  def start_link(%{id: id} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(id))
  end

  def init(%{name: name, source: source, csv_params: csv_params}) do
    {:ok, create(name, source, csv_params)}
  end

  def via_tuple(id), do: {:via, Registry, {Registry.Dataset, id}}

  alias __MODULE__
  alias SwarmEngine.{Connector, Tracker, Util}
  alias SwarmEngine.Connectors.LocalDir

  defstruct [:name, :tracker, :columns, :dataset, :csv_params]

  @default_csv_params [headers: true]

  def create(name, source, params \\ @default_csv_params) do
    csv_params = Keyword.merge(@default_csv_params, params)
    tracker = source
    |> Tracker.create(%LocalDir{path: "/tmp/swarm_engine_store/"})
    |> Tracker.sync()

    cols = columns(tracker, csv_params)

    dataset = %Dataset{
      name: name |> String.downcase() |> String.replace(~r/\s+/, "_"),
      columns: sql_columns(cols)
    }

    Dataset.create(dataset)

    %CSV{
      name: name,
      tracker: tracker,
      columns: cols,
      dataset: dataset,
      csv_params: csv_params
    }
  end

  def stream(%CSV{tracker: tracker, csv_params: csv_params}, version) do
    with {:ok, resource} <- Tracker.find(tracker, %{version: version}),
      source <- resource.source
    do
      source
      |> _stream(csv_params)
    else
      {:error, reason} -> {:error, reason}
      any -> {:error, any}
    end
  end

  def stream(%CSV{tracker: tracker, csv_params: csv_params}) do
    tracker
    |> Tracker.current()
    |> Map.get(:source)
    |> _stream(csv_params)
  end

  defp _stream(resource, csv_params) do
    tmp_file_path = "/tmp/#{Util.UUID.generate}"

    resource
    |> Connector.request
    |> Stream.into(File.stream!(tmp_file_path))
    |> Stream.run

    File.stream!(tmp_file_path)
    |> Util.CSV.decode!(csv_params)
  end

  def sync(%CSV{tracker: tracker, columns: columns, csv_params: csv_params} = dataset) do
    tracker = Tracker.sync(tracker)
    new_columns = columns(tracker, csv_params)

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

  defp _load(%CSV{dataset: dataset, csv_params: csv_params}, resource) do
    version = resource.modified_at
    stream = _stream(resource.source, csv_params) |> Stream.map(fn(row) ->
      Enum.map(dataset.columns, &(row[&1.original]))
    end)

    Dataset.insert_stream(dataset, stream, version)
  end

  defp columns(%Tracker{} = tracker, csv_params \\ [headers: false]) do
    tracker
      |> Tracker.current()
      |> Map.get(:source)
      |> columns(csv_params)
  end

  defp columns(source, csv_params) do
    source
    |> Connector.request()
    |> Stream.take(1)
    |> Enum.map(&(:binary.split(&1,"\n") |> List.first))
    |> Util.CSV.decode!(Keyword.merge(csv_params, [headers: false]))
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
