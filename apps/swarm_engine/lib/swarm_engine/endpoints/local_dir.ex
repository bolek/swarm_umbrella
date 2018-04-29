defmodule SwarmEngine.Endpoints.LocalDir do
  alias SwarmEngine.Endpoints.{LocalDir, LocalFile}
  alias SwarmEngine.Resource
  alias SwarmEngine.Util.UUID

  @type t :: %__MODULE__{path: String.t()}

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:path, :string)
  end

  def changeset(%LocalDir{} = local_dir, attrs) do
    local_dir
    |> cast(attrs, ~w(path))
    |> validate_required([:path])
  end

  @spec store(Resource.t(), LocalDir.t()) :: {:ok, Resource.t()}
  def store(%Resource{source: endpoint} = resource, %LocalDir{path: path}) do
    ext = Path.extname(resource.name)
    store_endpoint = LocalFile.create(new_path(path, ext))

    endpoint
    |> SwarmEngine.Consumer.stream()
    |> SwarmEngine.Producer.into(store_endpoint)
    |> Stream.run()

    {:ok, %{resource | source: store_endpoint}}
  end

  defp new_path(base_path, extension) do
    base_path
    |> Path.join(Date.to_iso8601(Date.utc_today(), :basic))
    |> Path.join("#{UUID.generate()}#{extension}")
  end
end
