defmodule SwarmEngine.Connectors.LocalFile do
  def get(%{path: path}, _opts \\ []) do
    File.stream!(path, [], 2048)
  end
end
