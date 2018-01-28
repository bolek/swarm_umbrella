require IEx

defmodule SwarmEngine.DatasetStore do
  alias Ecto.Adapters.SQL
  alias SwarmEngine.{DatasetStore, DataVault}

  import Ecto.Query

  @enforce_keys [:name, :columns]
  defstruct [:name, :columns]

  def create(%{name: name, columns: columns} = dataset) do
    store = %DatasetStore{name: name, columns: columns}
    case create_table(store) do
      {:ok, _} -> {:ok, store}
      {:error, %Postgrex.Error{postgres: %{code: :duplicate_table}}} -> :ok
    end
  end

  def insert(%DatasetStore{} = dataset, data, version \\ DateTime.utc_now) do
    insert_stream(dataset, data, version)
  end

  def insert_stream(%DatasetStore{name: name, columns: columns}, stream, version \\ DateTime.utc_now) do
    with column_names <- [:swarm_id | Enum.map(columns, &(&1.name))],
      insert_opts <- [{:on_conflict, :nothing}, {:conflict_target, [:swarm_id]}],
      {:ok, :ok} <- DataVault.transaction(fn ->
        from("#{name}_v", where: [version: ^version])
        |> DataVault.delete_all()

        stream
        |> Stream.map(&([generate_hash(&1) | &1]))
        |> Stream.map(&(Enum.zip(column_names, &1)))
        |> Stream.chunk_every(500)
        |> Stream.map(fn rows ->
            DataVault.insert_all(name, rows, insert_opts)
            rows
          end)
        |> Stream.map(fn rows -> Enum.map(rows, &([List.first(&1), version: version])) end)
        |> Stream.map(fn rows -> DataVault.insert_all(name <> "_v", rows) end)
        |> Stream.run
      end)
    do
      :ok
    else
      any -> {:error, any}
    end
  end

  def exists?(%DatasetStore{name: name}) do
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

  def table_columns(%DatasetStore{} = dataset) do
    with true <- DatasetStore.exists?(dataset),
      {:ok, result} <- query_columns(dataset),
      columns <- parse_columns(result.rows)
    do
      {:ok, columns}
    else
      false -> {:error, :dataset_without_table}
    end
  end

  def versions(%DatasetStore{name: name}) do
    query = from(v in "#{name}_v",
      distinct: [desc: v.version],
      select: type(v.version, :utc_datetime),
      order_by: [desc: v.version])

    DataVault.all(query)
  end

  defp generate_hash(list) do
    :crypto.hash(:md5 , Enum.join(list, ""))
  end

  defp create_table(%DatasetStore{name: name, columns: columns}) do
    SQL.query(DataVault, """
      CREATE TABLE #{name} (
        swarm_id uuid,
        #{to_sql_columns(columns)},
        PRIMARY KEY(swarm_id)
      );
    """)

    SQL.query(DataVault, """
      CREATE TABLE #{name}_v (
        swarm_id uuid NOT NULL REFERENCES #{name} (swarm_id),
        version timestamptz NOT NULL,
        loaded_at timestamptz NOT NULL DEFAULT NOW()
      );
    """)
  end

  defp query_columns(%DatasetStore{name: name}) do
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

  def from_map(%{"name" => name, "columns" => columns}) do
    from_map(%{name: name, columns: columns})
  end

  def from_map(%{} = m) do
    %DatasetStore{name: m.name, columns: m.columns}
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.DatasetStore do
  alias SwarmEngine.DatasetStore
  def to_map(%DatasetStore{} = ds) do
    %{
      name: ds.name,
      columns: ds.columns
    }
  end
end
