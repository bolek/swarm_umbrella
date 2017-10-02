defmodule SwarmEngine.Connector do
  def request({c, _, _} = source), do: c.request(source)
  def metadata({c, _, _} = source), do: c.metadata(source)
  def store(source, {c, _, _} = target), do: c.store(source, target)
  def list({c, _, _} = source), do: c.list(source)
end
