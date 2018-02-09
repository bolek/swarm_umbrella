defmodule SwarmEngine.Connectors.LocalFile do
  alias __MODULE__
  alias SwarmEngine.{Connector, Resource}

  @type t :: %__MODULE__{
    path: String.t,
    options: keyword
  }
  defstruct [:path, :options]

  @spec create(String.t, keyword) :: LocalFile.t
  def create(path, options \\ []) do
    %LocalFile{path: path, options: options}
  end

  @spec metadata!(Connector.t) :: Resource.t
  def metadata!(source) do
    case Connector.metadata(source) do
      {:ok, m} -> m
      {:error, reason} -> raise Kernel.inspect(reason)
    end
  end

  @spec store(Resource.t, LocalFile.t) :: {:ok, Resource.t}
  def store(%Resource{source: source} = resource, %LocalFile{path: path} = new_location) do
    File.mkdir_p(Path.dirname(path))

    Connector.request(source)
    |> Stream.into(File.stream!(path))
    |> Stream.run

    {:ok, %{resource | source: new_location}}
  end

  @spec store_stream(Enumerable.t, LocalFile.t) :: {:ok, Resource.t} | {:error, any}
  def store_stream(stream, %LocalFile{path: path} = source) do
    stream
    |> Stream.into(File.stream!(path))
    |> Stream.run

    Connector.metadata(source)
  end

  def from_map(%{"args" => %{"path" => path, "options" => options}}) do
    %LocalFile{
      path: path,
      options: options
    }
  end

  def from_map(%{args: %{path: path, options: options}}) do
    %LocalFile{
      path: path,
      options: options
    }
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Connectors.LocalFile do
  alias SwarmEngine.Connectors.LocalFile
  alias SwarmEngine.Resource

  @spec list(LocalFile.t) :: {:ok, list(Resource.t)}
  def list(%LocalFile{path: path} = location) do
    {:ok ,  Path.wildcard(path)
            |> Stream.map(&(%{location | path: &1}))
            |> Stream.map(&LocalFile.metadata!(&1))
            |> Enum.to_list
    }
  end

  @spec metadata(LocalFile.t) :: {:ok, Resource.t} | {:error, any}
  def metadata(%LocalFile{path: path} = source) do
    with  {:ok, info} <-
            File.stat(path, [])
    do
      {:ok, %Resource{
          name: Path.basename(path),
          size: info.size,
          modified_at: info.mtime |> Calendar.NaiveDateTime.to_date_time_utc,
          source: source
        }
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec request(LocalFile.t) :: Enumerable.t
  def request(%LocalFile{path: path}) do
    File.stream!(path, [], 2048)
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Connectors.LocalFile do
  alias SwarmEngine.Connectors.LocalFile
  def to_map(%LocalFile{} = f) do
    %{
      type: SwarmEngine.Connectors.LocalFile,
      args: %{path: f.path, options: f.options}
    }
  end
end
