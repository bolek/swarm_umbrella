use Mix.Config

config :swarm_engine, SwarmEngine.DataVault,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "data_vault_test"

config :swarm_engine, :http_client, SwarmEngine.Adapters.HTTP.Test
