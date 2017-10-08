use Mix.Config

config :swarm, ecto_repos: [Swarm.Repo]

import_config "#{Mix.env}.exs"
