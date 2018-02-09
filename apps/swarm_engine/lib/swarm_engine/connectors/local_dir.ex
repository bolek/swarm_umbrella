defmodule SwarmEngine.Connectors.LocalDir do
  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.Resource
  alias SwarmEngine.Util.UUID

  @type t :: %__MODULE__{ path: String.t }

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :path, :string
  end

  def changeset(%LocalDir{} = local_dir, attrs) do
    local_dir
    |> cast(attrs, [:path])
    |> validate_required([:path])
  end

  @spec store(Resource.t, LocalDir.t) :: {:ok, Resource.t}
  def store(%Resource{} = resource, %LocalDir{path: path}) do
    ext = Path.extname(resource.name)

    LocalFile.store(resource, LocalFile.create(new_path(path,ext)))
  end

  defp new_path(base_path, extension) do
    base_path
    |> Path.join(Date.to_iso8601(Date.utc_today, :basic))
    |> Path.join("#{UUID.generate}#{extension}")
  end

  def from_map(%{"args" => %{"path" => path}}) do
    %LocalDir{path: path}
  end

  def from_map(%{args: %{path: path}}) do
    %LocalDir{path: path}
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Connectors.LocalDir do
  alias SwarmEngine.Connectors.LocalDir

  def to_map(%LocalDir{} = d) do
    %{
      type: SwarmEngine.Connectors.LocalDir,
      args: %{path: d.path}
    }
  end
end
