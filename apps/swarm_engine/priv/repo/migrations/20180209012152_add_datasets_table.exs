defmodule SwarmEngine.Repo.Migrations.AddDatasetsTable do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    create table(:datasets, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:source, :map, null: false)
      add(:decoder, :map, null: false)
      add(:store, :map, null: true)
      add(:status, :string, null: false)

      timestamps()
    end

    create(unique_index("datasets", [:source], concurrently: true))
  end

  def down do
    drop(table(:datasets))
  end
end
