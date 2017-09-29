defmodule SwarmEngine.Connectors.LocalFile do
  alias SwarmEngine.Connector

  @type t :: {module, Map.t, Keyword.t}

  def create(params, options \\ []) do
    {__MODULE__, params, options}
  end

  def request({__MODULE__, %{path: path}, _opts}) do
    File.stream!(path, [], 2048)
  end

  def request_metadata({__MODULE__, %{path: path}, opts} = source) do
    with  {:ok, info} <-
            File.stat(path, opts)
    do
      {:ok, %{filename: Path.basename(path),
              size: info.size,
              modified_at: info.mtime |> Calendar.NaiveDateTime.to_date_time_utc,
              source: source
            }
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def store(resource, {__MODULE__, %{path: path}, _opts} = new_location) do
    Connector.request(resource.source)
    |> Stream.into(File.stream!(path))
    |> Stream.run

    {:ok, %{resource | source: new_location}}
  end

  def store_stream(stream, {__MODULE__, %{path: path}, _opts} = source) do
    stream
    |> Stream.into(File.stream!(path))
    |> Stream.run

    request_metadata(source)
  end
end
