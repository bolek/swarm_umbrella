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

  def insert(%Dataset{name: name, columns: columns}, data) do
    column_names = [:_full_hash | Enum.map(columns, &(&1.name))]

    stream = data
    |> Stream.map(&([generate_hash(&1) | &1]))
    |> Stream.map(&(Enum.zip(column_names, &1)))
    |> Stream.chunk_every(500)
    |> Stream.map(&IO.inspect(&1))

    Enum.each(stream, &(DataVault.insert_all name, &1,
      [ {:on_conflict, :nothing}, {:conflict_target, [:_full_hash]} ]
    ))
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
    |> Base.encode64()
  end

  defp create_table(%Dataset{name: name, columns: columns}) do
    SQL.query(DataVault, """
      CREATE TABLE #{name} (
        _id uuid DEFAULT uuid_generate_v4(),
        #{to_sql_columns(columns)},
        _created_at timestamptz DEFAULT NOW(),
        _full_hash varchar,
        PRIMARY KEY(_full_hash),
        CONSTRAINT id_unique_idx UNIQUE(_id)
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
