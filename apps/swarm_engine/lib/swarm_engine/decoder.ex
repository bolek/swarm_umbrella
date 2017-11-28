defmodule SwarmEngine.Decoder do
  def columns(source, decoder), do:
    decoder.__struct__.columns(source, decoder)

  def decode!(resource, decoder), do:
    decoder.__struct__.decode!(resource, decoder)
end
