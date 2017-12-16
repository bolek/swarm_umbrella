defmodule Swarm.Repo.Migrations.RemoveUrlFieldFromDatasets do
  use Ecto.Migration

  def change do
    alter table(:datasets) do
      remove :url
    end
  end
end
