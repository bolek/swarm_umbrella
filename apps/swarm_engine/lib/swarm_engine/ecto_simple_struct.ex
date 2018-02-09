defmodule SwarmEngine.EctoSimpleStruct do
  @behaviour Ecto.Type
  def type, do: :map

  # Provide custom casting rules.
  def cast(%{__struct__: _} = struct) do
    {:ok, struct}
  end

  def cast(%{type: type, args: args}) do
    data = Enum.map(args, fn x -> x end)

    {:ok, struct!(String.to_existing_atom(type), data)}
  end

  # Everything else is a failure though
  def cast(_), do: :error

  def load(%{"type" => type, "args" => args}) do
    data =
      for {key, val} <- args do
        {String.to_existing_atom(key), val}
      end
    {:ok, struct!(String.to_existing_atom(type), data)}
  end

  def dump(%{__struct__: type} = struct), do:
    {:ok, %{type: type, args: Map.from_struct(struct)}}

  def dump(_), do: :error
end
