# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :swarm_engine,
  ecto_repos: [SwarmEngine.DataVault, SwarmEngine.Repo]

# Adapters

config :swarm_engine, :http_client, SwarmEngine.Adapters.HTTP.Hackney
config :swarm_engine, :google_auth_client, SwarmEngine.Adapters.GoogleAuth.Goth

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :swarm_engine, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:swarm_engine, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#

config :goth,
  json: """
    {
    "type": "service_account",
    "project_id": "",
    "private_key_id": "",
    "private_key": "",
    "client_email": "",
    "client_id": "",
    "auth_uri": "",
    "token_uri": "",
    "auth_provider_x509_cert_url": "",
    "client_x509_cert_url": ""
    }
  """

import_config "#{Mix.env}.exs"
