defmodule SwarmEngine.Connectors.LocalFile do
  def request(%{path: path}, _opts \\ []) do
    File.stream!(path, [], 2048)
  end

  def request_metadata(%{path: path}, opts \\ []) do
    with  {:ok, info} <-
            File.stat(path, opts)
    do
      {:ok, %{filename: Path.basename(path), size: info.size}}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
