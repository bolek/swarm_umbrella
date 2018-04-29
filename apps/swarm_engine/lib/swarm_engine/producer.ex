defprotocol SwarmEngine.Producable do
  def into(endpoint, stream)
end

defmodule SwarmEngine.Producer do
  def into(stream, endpoint), do: SwarmEngine.Producable.into(endpoint, stream)
end
