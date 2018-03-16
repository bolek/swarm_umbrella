# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :swarm_web,
  namespace: SwarmWeb,
  ecto_repos: [Swarm.Repo]

# Configures the endpoint
config :swarm_web, SwarmWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6rMtrQG8VCY5f9GSczjxc0hfPH3Sbbmc1mQEPfAPR1uGW2HeSFJU4yGX44CKL60v",
  render_errors: [view: SwarmWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SwarmWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :swarm_web, :generators,
  context_app: :swarm

config :ueberauth, Ueberauth,
  providers: [
    identity: { Ueberauth.Strategy.Identity, [
      callback_methods: ["POST"],
      callback_path: "/api/auth/identity/callback",
      nickname_field: :email,
      param_nesting: "user",
      uid_field: :id
    ]}
  ]

config :swarm_web, SwarmWeb.Auth.Guardian,
  issuer: "swarm_web",
  secret_key: "use mix phx.gen.secret in production yo"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
