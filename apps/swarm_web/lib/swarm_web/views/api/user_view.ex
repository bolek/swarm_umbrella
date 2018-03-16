defmodule SwarmWeb.Api.UserView do
  use SwarmWeb, :view
  alias SwarmWeb.Api.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      name: user.name}
  end
end
