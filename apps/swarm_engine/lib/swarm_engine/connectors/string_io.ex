defmodule SwarmEngine.Connectors.StringIO do
  alias __MODULE__
  alias SwarmEngine.{Connector, Resource}

  use Ecto.Schema
  import Ecto.Changeset


  @primary_key false
  embedded_schema do
    field :type, :string, default: "StringIO"
    field :name, :string
    field :content, :string
  end

  def changeset(%StringIO{} = local_file, attrs) do
    local_file
    |> cast(attrs, ~w(content name))
    |> validate_required([:content, :name])
  end

  def create(name, content) do
    %StringIO{content: content, name: name}
  end

  @spec metadata!(Connector.t) :: Resource.t
  def metadata!(source) do
    case Connector.metadata(source) do
      {:ok, m} -> m
      {:error, reason} -> raise Kernel.inspect(reason)
    end
  end

  def fields(), do: __MODULE__.__schema__(:fields)
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Connectors.StringIO do
  alias SwarmEngine.Connectors.StringIO
  alias SwarmEngine.Resource

  @spec list(Connector.t) :: {:ok, list(Resource.t)} | {:error, any}
  def list(%StringIO{} = source) do
    case metadata(source) do
      {:ok, resource} ->
        {:ok, [resource]}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec metadata(StringIO.t) :: {:ok, Resource.t} | {:error, any}
  def metadata(%StringIO{content: content, name: name} = source) do
    {:ok, %Resource{
        name: name,
        size: byte_size(content),
        modified_at: nil,
        source: source
      }
    }
  end

  @spec request(StringIO.t) :: Enumerable.t
  def request(%StringIO{content: content}), do: Stream.map([content], &(&1))
end
