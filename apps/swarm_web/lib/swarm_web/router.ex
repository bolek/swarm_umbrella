defmodule SwarmWeb.Router do
  use SwarmWeb, :router

  alias SwarmWeb.Api
  alias SwarmWeb.Router.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticate_user do
    plug :authenticate
  end

  scope "/auth", SwarmWeb do
    pipe_through [:browser]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  pipeline :authenticated do
    plug SwarmWeb.Auth.AccessPipeline
  end

  scope "/api" do
    pipe_through [:api]

    scope "/auth" do
      post "/identity/callback", Api.AuthenticationController, :identity_callback
    end

    pipe_through [:authenticated]

    resources "/datasets", Api.DatasetController, except: [:new, :edit]
    resources "/users", Api.UserController, except: [:new, :edit]
  end

  scope "/", SwarmWeb do
    pipe_through [:browser, :authenticate_user]

    get "/", PageController, :index
  end

  defp authenticate(conn, _) do
    case get_session(conn, :current_user) do
      nil ->  conn
              |> redirect(to: Helpers.auth_path(conn, :request, :identity, %{}))
              |> halt()
      _ -> conn
            |> assign(:current_user, SwarmWeb.Session.current_user(conn))
    end
  end
end
