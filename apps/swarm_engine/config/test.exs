use Mix.Config

config :swarm_engine, SwarmEngine.DataVault,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "data_vault_test",
  after_connect: {SwarmEngine.DataVault, :set_utc, []}

config :swarm_engine, SwarmEngine.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "swarm_engine_repo_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  after_connect: {SwarmEngine.DataVault, :set_utc, []}

config :argon2_elixir,
  t_cost: 2,
  m_cost: 12

config :swarm_engine, :http_client, SwarmEngine.Adapters.HTTP.Test
config :swarm_engine, :google_auth_client, SwarmEngine.Adapters.GoogleAuth.Test

config :logger, level: :warn
