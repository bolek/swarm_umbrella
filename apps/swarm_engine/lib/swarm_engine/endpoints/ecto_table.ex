defmodule SwarmEngine.Endpoints.EctoTable do
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "EctoTable")
    field(:repo, :string)
    field(:table_name, :string)
  end

  def create(repo, table_name) do
    %EctoTable{repo: repo, table_name: table_name}
  end

  def resolve_repo(%EctoTable{repo: repo}), do: String.to_existing_atom("Elixir." <> repo)

  defimpl SwarmEngine.Consumable do
    import Ecto.Query, only: [from: 2]

    def stream(%EctoTable{table_name: table_name} = endpoint) do
      repo = EctoTable.resolve_repo(endpoint)

      Ecto.Adapters.SQL.stream(repo, "SELECT * FROM #{table_name}", [], max_rows: 500)
      |> Stream.map(fn result ->
        SwarmEngine.Message.create(result.rows, %{columns: result.columns})
      end)
    end
  end

  defimpl SwarmEngine.Producable do
    def into(%EctoTable{table_name: table_name} = endpoint, stream) do
      repo = EctoTable.resolve_repo(endpoint)

      stream
      |> Stream.chunk_every(500)
      |> Stream.map(fn messages ->
        repo.insert_all(table_name, Enum.map(messages, &Map.get(&1, :body)))
        messages
      end)
    end
  end
end
