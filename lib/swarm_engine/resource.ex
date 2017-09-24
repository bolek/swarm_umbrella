defmodule SwarmEngine.Resource do
  alias __MODULE__
  alias SwarmEngine.Util.{UUID,Zip}

  @enforce_keys [:id, :name, :connectors]
  defstruct [:id, :name, :connectors]

  @temp_file_path '/tmp'

  def create(name) do
    { :ok, %Resource{id: UUID.generate, name: name, connectors: []} }
  end

  def pull(resource, path, connector, %{} = params, options \\ []) do
    target_path = build_path(resource, path)
    tmp_path = gen_temp_path()

    connector.get(params, options)
      |> Stream.into(File.stream!(tmp_path))
      |> Stream.run

      File.mkdir_p(resource_dir(resource))
      move(tmp_path, target_path)
  end

  defp move(from, to) do
    case Zip.zipped?(from) do
      true ->
        Zip.unzip(from, [{:cwd, to}])
      false ->
        :ok = File.rename(from, to)
        {:ok, [to]}
    end
  end

  defp gen_temp_path do
    @temp_file_path ++ '/#{UUID.generate}'
  end

  defp resource_dir(resource), do: 'tmp/#{resource.id}'

  defp build_path(resource, path) do
    resource_dir(resource) ++ '/#{path}'
  end
end
