defprotocol SwarmEngine.Consumable do
  def stream(endpoint)
  def metadata(endpoint)
end

defmodule SwarmEngine.Consumer do
  def stream(endpoint), do: SwarmEngine.Consumable.stream(endpoint)
  def metadata(endpoint), do: SwarmEngine.Consumable.metadata(endpoint)
end
