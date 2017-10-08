defmodule Swarm.Application do
  @moduledoc """
  The Swarm Application Service.

  The swarm system business domain lives in this application.

  Exposes API to clients such as the `SwarmWeb` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link([
      supervisor(Swarm.Repo, []),
    ], strategy: :one_for_one, name: Swarm.Supervisor)
  end
end
