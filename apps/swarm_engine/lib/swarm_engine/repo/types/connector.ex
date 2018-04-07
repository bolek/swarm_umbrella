defmodule SwarmEngine.Repo.Types.Connector do
  alias SwarmEngine.Connectors
  @moduledoc """
  Dynamic embed type for `tracker.source` field.
  """
  use SwarmEngine.Repo.Types.DynamicEmbed

  @doc """
  Returns related struct based on data structure.
  """
  def resolve(%{type: "LocalFile"}), do: {:ok, Connectors.LocalFile}
  def resolve(%{type: "GoogleDrive"}), do: {:ok, Connectors.GoogleDrive}
  def resolve(%{type: "StringIO"}), do: {:ok, Connectors.StringIO}
  def resolve(_),
    do: {:error, :unkown_type}

  @doc """
  Returns list of supported `type`'s.
  """
  def types, do: [
    "LocalFile",
    "GoogleDrive",
    "StringIO"
  ]
end
