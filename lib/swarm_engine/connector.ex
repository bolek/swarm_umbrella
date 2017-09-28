defmodule SwarmEngine.Connector do

  def request({c, _, _} = source), do: c.request(source)
  def request_metadata({c, _, _} = source), do: c.request_metadata(source)
end
