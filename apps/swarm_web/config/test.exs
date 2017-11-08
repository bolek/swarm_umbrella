use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :swarm_web, SwarmWeb.Endpoint,
  http: [port: 4001],
  server: false

config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1
