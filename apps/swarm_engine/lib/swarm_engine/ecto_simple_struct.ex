defmodule SwarmEngine.EctoSimpleStruct do

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Ecto.Type

      @namespace Keyword.fetch!(opts, :namespace)

      def type, do: :map

      # Provide custom casting rules.
      def cast(%{__struct__: _} = struct) do
        {:ok, struct}
      end

      def cast(%{type: type, args: args}) do
        data = Enum.map(args, fn x -> x end)

        {:ok, struct!(get_module(type), data)}
      end

      # Everything else is a failure though
      def cast(_), do: :error

      def load(%{"type" => type, "args" => args}) do
        data =
          for {key, val} <- args do
            {String.to_existing_atom(key), val}
          end

        {:ok, struct!(get_module(type), data)}
      end

      def dump(%{__struct__: module} = struct), do:
        {:ok, %{type: get_type(module), args: Map.from_struct(struct)}}

      def dump(_), do: :error

      defp get_module(type), do: Module.concat(@namespace, type)
      defp get_type(module), do: Module.split(module) |> List.last

    end
  end
end
