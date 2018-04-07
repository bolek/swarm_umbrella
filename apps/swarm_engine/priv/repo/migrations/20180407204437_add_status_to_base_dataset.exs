defmodule SwarmEngine.Repo.Migrations.AddStatusToBaseDataset do
  use Ecto.Migration

  def up do
    alter table(:base_datasets) do
      add(:status, :string, null: false)
    end
  end

  def down do
    alter table(:base_datasets) do
      remove(:status)
    end
  end
end
