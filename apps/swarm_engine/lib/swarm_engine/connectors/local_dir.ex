defmodule SwarmEngine.Connectors.LocalDir do
  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.Resource
  alias SwarmEngine.Util.UUID

  @type t :: %__MODULE__{ path: String.t }
  defstruct [:path]

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
end
