defmodule SwarmEngine.Repo.Migrations.AddTrackersTable do
  use Ecto.Migration

  def change do
    create table(:trackers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :source, :map, null: false
      add :store, :map, null: false
      add :resources, {:array, :map}, null: false, default: []
      add :dataset_id, references(:datasets, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
