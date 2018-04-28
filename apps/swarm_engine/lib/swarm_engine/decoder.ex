defmodule SwarmEngine.Decoder do
  @callback decode!(Endpoint.t(), struct()) :: Enumerable.t()
  def decode!(endpoint, %{__struct__: type} = decoder), do: type.decode!(endpoint, decoder)

  @callback columns(Endpoint.t(), struct()) :: map
  def columns(endpoint, %{__struct__: type} = decoder), do: type.columns(endpoint, decoder)
end
