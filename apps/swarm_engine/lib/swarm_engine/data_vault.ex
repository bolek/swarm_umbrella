defmodule SwarmEngine.DataVault do
  use Ecto.Repo, otp_app: :swarm_engine

  def set_utc(conn)  do
    Postgrex.query!(conn, "SET TIME ZONE UTC;", [])
  end
end
