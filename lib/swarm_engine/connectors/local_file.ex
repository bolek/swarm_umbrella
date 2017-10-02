defmodule SwarmEngine.Connectors.LocalFile do
  alias SwarmEngine.Connector
  alias SwarmEngine.Util.UUID

  @type t :: {module, Map.t, Keyword.t}

  def create(params, options \\ []) do
    {__MODULE__, params, options}
  end

  def request({__MODULE__, %{path: path}, _opts}) do
    File.stream!(path, [], 2048)
  end

  def metadata({__MODULE__, %{path: path}, opts} = source) do
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

  def metadata!(source) do
    case metadata(source) do
      {:ok, m} -> m
      {:error, reason} -> raise Kernel.inspect(reason)
    end
  end

  def store(resource, {__MODULE__, %{base_path: path}, _opts} = location) do
    ext = Path.extname(resource.filename)
    new_location = put_elem(location, 1, %{path: new_path(path,ext)})

    store(resource, new_location)
  end

  def store(resource, {__MODULE__, %{path: path}, _o} = new_location) do
    File.mkdir_p(Path.dirname(path))

    Connector.request(resource.source)
    |> Stream.into(File.stream!(path))
    |> Stream.run

    {:ok, %{resource | source: new_location}}
  end

  def store_stream(stream, {__MODULE__, %{path: path}, _opts} = source) do
    stream
    |> Stream.into(File.stream!(path))
    |> Stream.run

    metadata(source)
  end

  def list({__MODULE__, %{path: path}, _opts} = location) do
    {:ok ,  Path.wildcard(path)
            |> Stream.map(&(put_elem(location, 1, %{path: &1})))
            |> Stream.map(&metadata!(&1))
            |> Enum.to_list
    }
  end

  defp new_path(base_path, extension) do
    base_path
    |> Path.join(Date.to_iso8601(Date.utc_today, :basic))
    |> Path.join("#{UUID.generate}#{extension}")
  end
end
