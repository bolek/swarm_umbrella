use Mix.Config

# Configure your database
config :swarm, Swarm.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "swarm_dev",
  hostname: "localhost",
  pool_size: 10
