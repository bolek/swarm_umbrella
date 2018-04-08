defmodule SwarmEngine.Repo.Migrations.AddTrackerResourcesTable do
  use Ecto.Migration

  def up do
    create table(:tracker_resources, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:size, :int, null: false)
      add(:modified_at, :utc_datetime, null: false)
      add(:source, :map, null: false)
      add(:tracker_id, references(:trackers, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end
  end

  def down do
    drop(table(:tracker_resources))
  end
end
