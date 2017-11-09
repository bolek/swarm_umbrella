defmodule SwarmWeb.Router do
  use SwarmWeb, :router

  alias SwarmWeb.DatasetController
  alias SwarmWeb.UserController

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]

    resources "/datasets", DatasetController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
  end

  scope "/", SwarmWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", SwarmWeb do
  #   pipe_through :api
  # end
end
