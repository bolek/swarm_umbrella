defmodule SwarmEngine.Endpoints.StringIO do
  alias __MODULE__
  alias SwarmEngine.{Consumer, Consumable, Resource}

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "StringIO")
    field(:name, :string)
    field(:content, :string)
  end

  def changeset(%StringIO{} = local_file, %StringIO{} = new) do
    local_file
    |> change(Map.from_struct(new))
  end

  def changeset(%StringIO{} = local_file, attrs) do
    local_file
    |> cast(attrs, ~w(content name))
    |> validate_required([:content, :name])
  end

  def create(name, content) do
    %StringIO{content: content, name: name}
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
    @spec metadata(StringIO.t()) :: {:ok, Resource.t()} | {:error, any}
    def metadata(%StringIO{content: content, name: name} = source) do
      {:ok,
       %Resource{
         name: name,
         size: byte_size(content),
         modified_at: nil,
         source: source
       }}
    end

    @spec stream(StringIO.t()) :: Enumerable.t()
    def stream(%StringIO{content: content} = endpoint) do
      {:ok, resource} = metadata(endpoint)

      [SwarmEngine.Message.create(content, %{size: byte_size(content), resource: resource})]
      |> Stream.map(& &1)
    end
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Endpoints.StringIO do
  alias SwarmEngine.Endpoints.StringIO
  alias SwarmEngine.{Consumer, Resource}

  @spec list(Connector.t()) :: {:ok, list(Resource.t())} | {:error, any}
  def list(%StringIO{} = source) do
    case Consumer.metadata(source) do
      {:ok, resource} ->
        {:ok, [resource]}

      {:error, error} ->
        {:error, error}
    end
  end
end
