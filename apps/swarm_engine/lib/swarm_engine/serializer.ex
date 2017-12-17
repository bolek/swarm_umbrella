defmodule SwarmEngine.Serializer do
  def encode!(%{__struct__: type} = struct) do
    %{
      type: type,
      map: encode!(Map.from_struct(struct))
    }
  end
  def encode!(x), do: x

  def decode!(%{type: type, map: map}) do
    struct(String.to_atom(type), map)
  end
  def decode!(x), do: x
end
