defmodule SwarmEngine.Decoders.CSV do
  alias __MODULE__
  alias SwarmEngine.Decoders.CSV
  alias SwarmEngine.{Connector, Util}

  @default_options [headers: true, separator: ",", delimiter: "\n"]

  @type t :: %CSV{
    options: keyword
  }

  defstruct [:options]

  @spec create(Keyword) :: CSV.t
  def create(options \\ []), do: %CSV{options: init_options(options)}

  @spec columns(Connector.t, CSV.t) :: Map
  def columns(source, %CSV{options: opts}) do
    opts = column_options(opts)
    delimiter = Keyword.get(opts, :delimiter, "\n")

    source
    |> Connector.request()
    |> Stream.take(1)
    |> Enum.map(&(:binary.split(&1, delimiter) |> List.first))
    |> Util.CSV.decode!(opts)
    |> Enum.to_list()
    |> List.first()
    |> Enum.map(fn c ->
      name = c
      |> String.downcase()
      |> String.replace(~r/\s+/, "_")

      %{original: c, name: name, type: "character varying"}
    end)
  end

  @spec decode!(Connector.t, CSV.t) :: Enumerable.t
  def decode!(source, %CSV{options: opts}) do
    tmp_file_path = "/tmp/#{Util.UUID.generate}"

    source
    |> Connector.request
    |> Stream.into(File.stream!(tmp_file_path))
    |> Stream.run

    File.stream!(tmp_file_path)
    |> Util.CSV.decode!(opts)
  end

  defp column_options(opts) do
    Keyword.merge(opts, [headers: false])
  end

  defp init_options(options), do: Keyword.merge(@default_options(), options)
end
