use Mix.Config

config :swarm_engine, SwarmEngine.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "swarm_engine_repo_dev",
  username: "postgres",
  hostname: "localhost",
  after_connect: {SwarmEngine.DataVault, :set_utc, []}

config :swarm_engine, SwarmEngine.DataVault,
  adapter: Ecto.Adapters.Postgres,
  database: "data_vault_dev",
  username: "postgres",
  hostname: "localhost",
  after_connect: {SwarmEngine.DataVault, :set_utc, []}
