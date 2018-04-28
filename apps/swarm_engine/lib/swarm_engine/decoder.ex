defmodule SwarmEngine.Decoder do
  @callback decode!(Connector.t(), struct()) :: Enumerable.t()
  def decode!(resource, %{__struct__: type} = decoder), do: type.decode!(resource, decoder)

  @callback columns(Connector.t(), struct()) :: map
  def columns(resource, %{__struct__: type} = decoder), do: type.columns(resource, decoder)
end
