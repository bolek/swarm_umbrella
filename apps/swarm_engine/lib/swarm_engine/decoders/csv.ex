defmodule SwarmEngine.Decoders.CSV do
  alias __MODULE__
  alias SwarmEngine.Decoders.CSV
  alias SwarmEngine.{Connector, Util}

  @type t :: %CSV{
    headers: Boolean.t,
    separator: String.t,
    delimiter: String.t
  }
  defstruct [:headers, :separator, :delimiter]

  @spec create(Keyword.t) :: CSV.t
  def create(options \\ []) do
    %CSV{
      headers: Keyword.get(options, :headers, true),
      separator: Keyword.get(options, :separator, ","),
      delimiter: Keyword.get(options, :delimiter, "\n")
    }
  end

  @spec columns(Connector.t, CSV.t) :: Map
  def columns(source, %CSV{delimiter: delimiter} = opts) do
    opts = column_options(opts)

    {:ok, source
    |> Connector.request()
    |> Stream.take(1)
    |> Enum.map(&(:binary.split(&1, delimiter) |> List.first))
    |> Util.CSV.decode!(Map.to_list(opts))
    |> Enum.to_list()
    |> List.first()
    |> Enum.map(fn c ->
      name = c
      |> String.downcase()
      |> String.replace(~r/\s+/, "_")

      %{original: c, name: name, type: "character varying"}
    end)}
  end

  @spec decode!(Connector.t, CSV.t) :: Enumerable.t
  def decode!(source, %CSV{} = opts) do
    tmp_file_path = "/tmp/#{Util.UUID.generate}"

    source
    |> Connector.request
    |> Stream.into(File.stream!(tmp_file_path))
    |> Stream.run

    File.stream!(tmp_file_path)
    |> Util.CSV.decode!(Map.to_list(opts))
  end

  defp column_options(opts), do: opts
    |> Map.replace(:headers, false)

  def from_map(%{"headers" => headers, "separator" => separator, "delimiter" => delimiter}) do
    from_map(%{headers: headers, separator: separator, delimiter: delimiter})
  end

  def from_map(c) do
    struct(CSV, c)
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Decoders.CSV do
  alias SwarmEngine.Decoders.CSV

  def to_map(%CSV{} = c) do
    Map.from_struct(c)
  end
end
