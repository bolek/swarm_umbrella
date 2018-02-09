defmodule SwarmEngine.Repo.Migrations.DropTrackerColumnFromDatasets do
  use Ecto.Migration

  def up do
    alter table(:datasets) do
      remove :tracker
    end
  end

  def down do
    alter table(:datasets) do
      add :tracker, :map, null: false
    end
  end
end
