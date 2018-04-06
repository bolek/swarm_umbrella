defmodule SwarmEngine.Repo.Migrations.AddBaseDatasetsTable do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    create table(:base_datasets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :source, :map, null: false
      add :decoder, :map, null: false

      timestamps()
    end

    create unique_index("base_datasets", [:source], concurrently: true)
  end

  def down do
    drop table(:base_datasets)
  end
end
