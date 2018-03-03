defmodule SwarmEngine.Repo.Types.Decoder do
  alias SwarmEngine.Decoders
  @moduledoc """
  Dynamic embed type for `tracker.source` field.
  """
  use SwarmEngine.Repo.Types.DynamicEmbed

  @doc """
  Returns related struct based on data structure.
  """
  def resolve(%{type: "CSV"}), do: {:ok, Decoders.CSV}
  def resolve(_), do: {:error, :unkown_type}

  @doc """
  Returns list of supported `type`'s.
  """
  def types, do: [
    "CSV"
  ]
end
