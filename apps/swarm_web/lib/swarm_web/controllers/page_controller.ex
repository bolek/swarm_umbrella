defmodule SwarmWeb.PageController do
  use SwarmWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
