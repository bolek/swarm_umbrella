defmodule SwarmEngine.Repo.Migrations.AddDatasetsTable do
  use Ecto.Migration

  def change do
    create table(:datasets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :tracker, :map, null: false
      add :store, :map, null: false
      add :decoder, :map, null: false

      timestamps()
    end
  end
end
