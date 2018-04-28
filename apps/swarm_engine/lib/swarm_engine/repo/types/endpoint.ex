defmodule SwarmEngine.Repo.Types.Endpoint do
  alias SwarmEngine.Endpoints

  @moduledoc """
  Dynamic embed type for `tracker.source` field.
  """
  use SwarmEngine.Repo.Types.DynamicEmbed

  @doc """
  Returns related struct based on data structure.
  """
  def resolve(%{type: "LocalFile"}), do: {:ok, Endpoints.LocalFile}
  def resolve(%{type: "GoogleDrive"}), do: {:ok, Endpoints.GoogleDrive}
  def resolve(%{type: "StringIO"}), do: {:ok, Endpoints.StringIO}
  def resolve(_), do: {:error, :unkown_type}

  @doc """
  Returns list of supported `type`'s.
  """
  def types,
    do: [
      "LocalFile",
      "GoogleDrive",
      "StringIO"
    ]
end
