defmodule SwarmEngine.Datasets.CSV do
  alias __MODULE__
  alias SwarmEngine.{Connector, Tracker, Util}
  alias SwarmEngine.Connectors.LocalFile

  defstruct [:name, :tracker, :columns]

  def create(name, %Tracker{} = tracker) do
    %CSV{name: name, tracker: tracker, columns: columns(tracker)}
  end

  def create(name, source) do
    tracker = source
    |> Tracker.create(LocalFile.create(%{base_path: "/tmp/swarm_engine_store/"}))
    |> Tracker.sync()

    %CSV{name: name, tracker: tracker, columns: columns(tracker)}
  end

  def stream(%CSV{tracker: tracker}) do
    tmp_file_path = "/tmp/#{Util.UUID.generate}"

    tracker
    |> Tracker.current()
    |> get_in([:source])
    |> Connector.request()
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
end
