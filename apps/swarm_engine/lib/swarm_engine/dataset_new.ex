defmodule SwarmEngine.DatasetNew do
  alias __MODULE__

  defstruct [:id, :name, :decoder, :source]

  def create(name, source, decoder) do
    {:ok, %DatasetNew{
      id: SwarmEngine.Util.UUID.generate,
      name: name,
      source: source,
      decoder: decoder
     }}
  end
end
