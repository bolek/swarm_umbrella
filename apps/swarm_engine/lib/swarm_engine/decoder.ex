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

  def from_map(%{"args" => args, "type" => type}), do:
    from_map(%{args: args, type: String.to_existing_atom(type)})

  def from_map(%{args: args, type: type}) when is_binary(type), do:
    from_map(%{args: args, type: String.to_existing_atom(type)})

  def from_map(%{args: args, type: type}), do:
    %Decoder{type: type, decoder: type.from_map(args)}
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Decoder do
  alias SwarmEngine.Decoder

  def to_map(%Decoder{} = d) do
    %{
      type: d.type,
      args: SwarmEngine.Mapable.to_map(d.decoder)
    }
  end
end
