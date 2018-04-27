defmodule SwarmEngine.Decoders.CSV do
  @behaviour SwarmEngine.Decoder

  alias __MODULE__
  alias SwarmEngine.Decoders.CSV
  alias SwarmEngine.{Connector, Util}

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %CSV{
          type: String.t(),
          headers: Boolean.t(),
          separator: String.t(),
          delimiter: String.t()
        }

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "CSV")
    field(:headers, :boolean, default: true)
    field(:separator, :string, default: ",")
    field(:delimiter, :string, default: "\n")
  end

  def changeset(%CSV{} = csv, %CSV{} = new) do
    csv
    |> change(Map.from_struct(new))
  end

  def changeset(%CSV{} = csv, attrs) do
    csv
    |> cast(attrs, ~w(headers separator delimiter))
  end

  @spec create(Keyword.t()) :: CSV.t()
  def create(options \\ []) do
    %CSV{
      headers: Keyword.get(options, :headers, true),
      separator: Keyword.get(options, :separator, ","),
      delimiter: Keyword.get(options, :delimiter, "\n")
    }
  end

  @spec columns(Connector.t(), struct()) :: Map
  def columns(source, %CSV{delimiter: delimiter} = opts) do
    opts = column_options(opts)

    {:ok,
     source
     |> Connector.request()
     |> Stream.take(1)
     |> Enum.map(&(:binary.split(Map.get(&1, :body), delimiter) |> List.first()))
     |> Util.CSV.decode!(Map.to_list(opts))
     |> Enum.to_list()
     |> List.first()
     |> Enum.map(fn c ->
       name =
         c
         |> String.downcase()
         |> String.replace(~r/\s+/, "_")
         |> String.replace(~r/-+/, "_")

       %{original: c, name: name, type: "character varying"}
     end)}
  end

  @spec decode!(Connector.t(), CSV.t()) :: Enumerable.t()
  def decode!(source, %CSV{} = opts) do
    tmp_file_path = "/tmp/#{Util.UUID.generate()}"

    source
    |> Connector.request()
    |> Stream.map(&Map.get(&1, :body))
    |> Stream.into(File.stream!(tmp_file_path))
    |> Stream.run()

    File.stream!(tmp_file_path)
    |> Util.CSV.decode!(Map.to_list(opts))
    |> Stream.map(&SwarmEngine.Message.create(&1, %{}))
  end

  defp column_options(opts) do
    case(Map.fetch(opts, :headers)) do
      {:ok, _} -> Map.put(opts, :headers, false)
      _ -> opts
    end
  end
end
