defmodule SwarmWeb.Session do
  def logged_in?(conn) do
    Plug.Conn.get_session(conn, :current_user) != nil
  end

  def current_user(conn) do
    conn
    |> Plug.Conn.get_session(:current_user)
    |> Swarm.Accounts.get_user!()
  end
end
