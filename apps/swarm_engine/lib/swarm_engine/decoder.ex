defmodule SwarmEngine.Decoder do
  alias __MODULE__

  @type t :: %Decoder{
    type: module,
    decoder: struct
  }
  defstruct [:type, :decoder]

  def create(%{__struct__: type} = decoder), do:
    %Decoder{type: type, decoder: decoder}

  def columns(source, %Decoder{type: type, decoder: decoder}), do:
    type.columns(source, decoder)

  def decode!(resource, %Decoder{type: type, decoder: decoder}), do:
    type.decode!(resource, decoder)
end
