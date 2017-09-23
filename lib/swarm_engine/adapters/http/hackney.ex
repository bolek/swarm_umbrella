defmodule SwarmEngine.Adapters.HTTP.Hackney do

  def get(term, url, headers, body, opts) do
    :hackney.request(term, url, headers, body, opts)
  end

  def stream(client) do
    :hackney.stream_body(client)
  end
end
