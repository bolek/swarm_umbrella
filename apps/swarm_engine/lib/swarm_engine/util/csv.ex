defmodule SwarmEngine.Util.CSV do
  def decode!(params, options \\ []), do: CSV.decode!(params, options)
end
