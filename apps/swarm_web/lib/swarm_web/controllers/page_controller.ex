defmodule SwarmWeb.PageController do
  use SwarmWeb, :controller

  def index(conn, _params) do
    current_user = get_session(conn, :current_user)
      |> Swarm.Accounts.get_user!()

    render conn, "index.html", current_user: current_user
  end
end
