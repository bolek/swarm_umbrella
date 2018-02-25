defmodule SwarmEngine.Decoder do
  alias __MODULE__

  @callback decode!(Connector.t, struct()) :: Enumerable.t
  def decode!(resource, %{__struct__: type} = decoder), do:
    type.decode!(resource, decoder)

  @callback columns(Connector.t, struct()) :: map
  def columns(resource, %{__struct__: type} = decoder), do:
    type.columns(resource, decoder)

  @callback type(struct()) :: String.t
  def type(%{__struct__: type} = decoder), do:
    type.type(decoder)

  @callback args(struct()) :: String.t
  def args(%{__struct__: type} = decoder), do:
    type.args(decoder)
end
