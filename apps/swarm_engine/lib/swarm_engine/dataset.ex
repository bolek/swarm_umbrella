alias Ecto.Adapters.SQL

defmodule SwarmEngine.Dataset do
  alias SwarmEngine.{Dataset, DataVault}

  @enforce_keys [:name, :columns]
  defstruct [:name, :columns]

  def create(%Dataset{} = dataset) do
    case create_table(dataset) do
      {:ok, _} -> :ok
      {:error, %Postgrex.Error{postgres: %{code: :duplicate_table}}} -> :ok
    end
  end

  def insert(%Dataset{} = dataset, data) do
    insert_stream(dataset, data)
  end

  def insert_stream(%Dataset{name: name, columns: columns}, stream) do
    column_names = [:swarm_id | Enum.map(columns, &(&1.name))]
    insert_opts = [{:on_conflict, :nothing}, {:conflict_target, [:swarm_id]}]

    DataVault.transaction(fn ->
      stream
      |> Stream.map(&([generate_hash(&1) | &1]))
      |> Stream.map(&(Enum.zip(column_names, &1)))
      |> Stream.chunk_every(500)
      |> Stream.map(fn rows ->
          DataVault.insert_all(name, rows, insert_opts)
          rows
        end)
      |> Stream.map(fn rows -> Enum.map(rows, &([List.first(&1)])) end)
      |> Stream.map(fn rows -> DataVault.insert_all(name <> "_v", rows) end)
      |> Stream.run
    end)
  end

  def exists?(%Dataset{name: name}) do
    case SQL.query(DataVault, """
      SELECT EXISTS (
        SELECT 1
        FROM   pg_catalog.pg_class c
        JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE  n.nspname = 'public'
        AND    c.relname = '#{name}'
      );
      """) do
      {:ok, %Postgrex.Result{rows: [[true]]}} -> true
      {:ok, %Postgrex.Result{rows: [[false]]}} -> false
    end
  end

  def columns(%Dataset{} = dataset) do
    with true <- Dataset.exists?(dataset),
      {:ok, result} <- query_columns(dataset),
      columns <- parse_columns(result.rows)
    do
      {:ok, columns}
    else
      false -> {:error, :dataset_without_table}
    end
  end

  defp generate_hash(list) do
    :crypto.hash(:md5 , Enum.join(list, ""))
  end

  defp create_table(%Dataset{name: name, columns: columns}) do
    SQL.query(DataVault, """
      CREATE TABLE #{name} (
        swarm_id uuid,
        #{to_sql_columns(columns)},
        swarm_created_at timestamptz NOT NULL DEFAULT NOW(),
        PRIMARY KEY(swarm_id)
      );
    """)

    SQL.query(DataVault, """
      CREATE TABLE #{name}_v (
        swarm_id uuid NOT NULL REFERENCES #{name} (swarm_id),
        loaded_at timestamptz NOT NULL DEFAULT NOW()
      );
    """)
  end

  defp query_columns(%Dataset{name: name}) do
    SQL.query(DataVault, """
      SELECT
        a.attnum AS col_order,
        a.attname AS col_name,
        pg_catalog.format_type(a.atttypid, a.atttypmod) AS col_type
      FROM pg_catalog.pg_class c
        LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        INNER JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
      WHERE a.attnum > 0
        AND NOT a.attisdropped
        AND c.relname = '#{name}'
        AND n.nspname ~ 'public'
      ORDER BY a.attnum
    """)
  end

  defp parse_columns(raw_columns) do
    raw_columns
    |> Enum.map(fn [order, name, type] -> %{order: order, name: name, type: type} end)
  end

  defp to_sql_columns(columns) do
    columns
      |> Enum.map(&("#{&1.name} #{&1.type}"))
      |> Enum.join(",")
  end
end
