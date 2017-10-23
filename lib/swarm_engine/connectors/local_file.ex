defmodule SwarmEngine.Connectors.LocalFile do
  alias __MODULE__
  alias SwarmEngine.Connector

  defstruct [:path, :options]

  def create(path, options \\ []) do
    %LocalFile{path: path, options: options}
  end

  def metadata!(source) do
    case Connector.metadata(source) do
      {:ok, m} -> m
      {:error, reason} -> raise Kernel.inspect(reason)
    end
  end

  def store(resource, %LocalFile{path: path} = new_location) do
    File.mkdir_p(Path.dirname(path))

    Connector.request(resource.source)
    |> Stream.into(File.stream!(path))
    |> Stream.run

    {:ok, %{resource | source: new_location}}
  end

  def store_stream(stream, %LocalFile{path: path} = source) do
    stream
    |> Stream.into(File.stream!(path))
    |> Stream.run

    Connector.metadata(source)
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Connectors.LocalFile do
  alias SwarmEngine.Connectors.LocalFile

  def list(%LocalFile{path: path} = location) do
    {:ok ,  Path.wildcard(path)
            |> Stream.map(&(%{location | path: &1}))
            |> Stream.map(&LocalFile.metadata!(&1))
            |> Enum.to_list
    }
  end

  def metadata(%LocalFile{path: path} = source) do
    with  {:ok, info} <-
            File.stat(path, [])
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

  def request(%LocalFile{path: path}) do
    File.stream!(path, [], 2048)
  end
end
