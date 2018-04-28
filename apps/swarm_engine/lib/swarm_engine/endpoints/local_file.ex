defmodule SwarmEngine.Endpoints.LocalFile do
  alias __MODULE__
  alias SwarmEngine.{Consumer, Consumable, Resource}

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          path: String.t()
        }

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "LocalFile")
    field(:path, :string)
  end

  def changeset(%LocalFile{} = local_file, %LocalFile{} = new) do
    local_file
    |> change(Map.from_struct(new))
  end

  def changeset(%LocalFile{} = local_file, attrs) do
    local_file
    |> cast(attrs, ~w(path))
    |> validate_required([:path])
  end

  @spec create(String.t()) :: LocalFile.t()
  def create(path) do
    %LocalFile{path: path}
  end

  @spec metadata!(Consumable.t()) :: Resource.t()
  def metadata!(endpoint) do
    case Consumer.metadata(endpoint) do
      {:ok, m} -> m
      {:error, reason} -> raise Kernel.inspect(reason)
    end
  end

  @spec store(Resource.t(), LocalFile.t()) :: {:ok, Resource.t()}
  def store(%Resource{source: source} = resource, %LocalFile{path: path} = new_location) do
    File.mkdir_p(Path.dirname(path))

    Consumer.stream(source)
    |> Stream.map(fn %SwarmEngine.Message{body: body} -> body end)
    |> Stream.into(File.stream!(path))
    |> Stream.run()

    {:ok, %{resource | source: new_location}}
  end

  @spec store_stream(Enumerable.t(), LocalFile.t()) :: {:ok, Resource.t()} | {:error, any}
  def store_stream(stream, %LocalFile{path: path} = source) do
    stream
    |> Stream.into(File.stream!(path))
    |> Stream.run()

    Consumer.metadata(source)
  end

  def fields(), do: __MODULE__.__schema__(:fields)

  defimpl SwarmEngine.Consumable do
    def metadata(%LocalFile{path: path} = endpoint) do
      with {:ok, info} <- File.stat(path, []) do
        {:ok,
         %Resource{
           name: Path.basename(path),
           size: info.size,
           modified_at:
             info.mtime
             |> NaiveDateTime.from_erl!(),
           source: endpoint
         }}
      else
        {:error, reason} -> {:error, reason}
      end
    end

    def stream(%LocalFile{path: path} = endpoint) do
      {:ok, resource} = metadata(endpoint)

      File.stream!(path, [], 2048)
      |> Stream.map(fn i ->
        SwarmEngine.Message.create(i, %{size: byte_size(i), resource: resource})
      end)
    end
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Endpoints.LocalFile do
  alias SwarmEngine.Endpoints.LocalFile
  alias SwarmEngine.Resource

  @spec list(LocalFile.t()) :: {:ok, list(Resource.t())}
  def list(%LocalFile{path: path} = location) do
    {:ok,
     Path.wildcard(path)
     |> Stream.map(&%{location | path: &1})
     |> Stream.map(&LocalFile.metadata!(&1))
     |> Enum.to_list()}
  end
end
