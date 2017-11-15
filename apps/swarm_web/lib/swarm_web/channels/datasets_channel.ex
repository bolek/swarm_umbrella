defmodule SwarmWeb.DatasetsChannel do
  use Phoenix.Channel

  require Logger

  def join("datasets", _, socket), do: {:ok, socket}

  def handle_in("fetch", _params, socket) do
    Logger.info "Handling datasets..."

    payload =[
      %{"title" => "Sample.csv", "url" => "google.com"},
      %{"title" => "Another.csv", "url" => nil}
    ]

    broadcast(socket, "datasets", %{datasets: payload})
    {:reply, :ok, socket}
  end

  def handle_in("track", params, socket) do
    Logger.info "Handling track new dataset"

    IO.inspect params

    broadcast(socket, "datasets", %{datasets: [params["msg"]]})

    {:reply, :ok, socket}
  end
end
