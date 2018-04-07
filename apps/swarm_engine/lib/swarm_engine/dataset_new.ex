defmodule SwarmEngine.DatasetNew do
  alias __MODULE__

  @enforce_keys [:id, :name, :decoder, :source]
  defstruct [:id, :name, :decoder, :source]

  def create(%{name: name, source: source} = attrs) do
    {:ok,
     %DatasetNew{
       id: Map.get(attrs, :id, SwarmEngine.Util.UUID.generate()),
       name: name,
       source: source,
       decoder: Map.get(attrs, :decoder, SwarmEngine.Decoders.CSV.create())
     }}
  end
end
