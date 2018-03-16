defmodule SwarmWeb.Auth.AccessPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :swarm_web,
    module: SwarmWeb.Auth.Guardian,
    error_handler: SwarmWeb.Auth.ErrorHandler
  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true
end
