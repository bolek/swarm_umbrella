defmodule SwarmWeb.Api.AuthenticationController do
  use SwarmWeb, :controller

  plug Ueberauth

  def identity_callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.uid
    password = auth.credentials.other.password
    handle_user_conn(Swarm.Accounts.authenticate_by_email_password(email, password), conn)
  end

  defp handle_user_conn({:ok, user}, conn) do
    {:ok, jwt, _full_claims} =
      SwarmWeb.Auth.Guardian.encode_and_sign(user, %{})

    conn
    |> put_resp_header("authorization", "Bearer #{jwt}")
    |> json(%{token: jwt})
  end

  defp handle_user_conn({:error, _reason}, conn) do
    conn
    |> put_status(401)
    |> json(%{message: "unauthorized"})
  end
end
