use Mix.Config

# Configure your database
config :swarm, Swarm.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "swarm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
