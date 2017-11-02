defmodule Swarm.Repo.Migrations.CreateDatasets do
  use Ecto.Migration

  def change do
    create table(:datasets) do
      add :name, :string
      add :url, :string

      timestamps()
    end

  end
end
