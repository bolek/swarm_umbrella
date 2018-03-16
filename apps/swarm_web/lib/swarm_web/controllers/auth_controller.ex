defmodule SwarmWeb.AuthController do
  @moduledoc """
  Auth controller responsible for handling Ueberauth responses
  """

  use SwarmWeb, :controller
  plug Ueberauth

  alias Swarm.Accounts
  alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    case get_session(conn, :current_user) do
      nil ->
        render(conn, "request.html", callback_url: Helpers.callback_url(conn))
      _ -> conn
            |> redirect(to: "/")
            |> halt()
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/auth/identity")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/auth/identity")
  end

  def callback(conn, %{"email" => email, "password" => password, "provider" => "identity"}) do
    case Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:current_user, user.id)
        |> redirect(to: "/")
      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: auth_path(conn, :request, :identity, %{email: email}))
    end
  end
end
