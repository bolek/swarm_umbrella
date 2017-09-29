defmodule SwarmEngine.Connector do

  def request({c, _, _} = source), do: c.request(source)
  def metadata({c, _, _} = source), do: c.metadata(source)
end
