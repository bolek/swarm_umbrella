defmodule :"Elixir.SwarmEngine.DataVault.Migrations.Add-uuid-extension" do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION \"uuid-ossp\"", "DROP EXTENSION \"uuid-ossp\""
  end
end
