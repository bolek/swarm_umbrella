defmodule Swarm.Repo.Migrations.AddCoreFieldsToDatasets do
  use Ecto.Migration

  def change do
    alter table(:datasets) do
      add :decoder, :map
      add :store, :map
      add :tracker, :map
    end
  end
end
