defmodule SwarmEngine.Connectors.LocalDir do
  alias SwarmEngine.Connectors.{LocalDir, LocalFile}
  alias SwarmEngine.Util.UUID

  defstruct [:path]

  def store(resource, %LocalDir{path: path}) do
    ext = Path.extname(resource.filename)

    LocalFile.store(resource, LocalFile.create(new_path(path,ext)))
  end

  defp new_path(base_path, extension) do
    base_path
    |> Path.join(Date.to_iso8601(Date.utc_today, :basic))
    |> Path.join("#{UUID.generate}#{extension}")
  end
end
