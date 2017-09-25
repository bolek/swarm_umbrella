defmodule SwarmEngine.Connectors.LocalFile do
  def request(%{path: path}, _opts \\ []) do
    File.stream!(path, [], 2048)
  end
end
