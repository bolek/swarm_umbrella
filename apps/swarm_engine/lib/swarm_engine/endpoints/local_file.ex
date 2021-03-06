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

    @spec stream(LocalFile.t()) :: Enumerable.t()
    def stream(%LocalFile{path: path} = endpoint) do
      {:ok, resource} = metadata(endpoint)

      File.stream!(path, [], 2048)
      |> Stream.map(fn i ->
        SwarmEngine.Message.create(i, %{size: byte_size(i), resource: resource})
      end)
    end
  end

  defimpl SwarmEngine.Producable do
    @spec into(LocalFile.t(), Enumerable.t()) :: Enumerable.t()
    def into(%LocalFile{path: path}, stream) do
      stream
      |> Stream.transform(
        fn ->
          File.mkdir_p(Path.dirname(path))

          File.open!(path, [:write])
        end,
        fn elem, file ->
          IO.binwrite(file, Map.get(elem, :body))
          {[elem], file}
        end,
        fn file ->
          File.close(file)
        end
      )
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
