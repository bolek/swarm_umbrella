defmodule SwarmWeb.DatasetsChannel do
  use Phoenix.Channel


  require Logger

  def join("datasets", _, socket), do: {:ok, socket}

  def handle_in("fetch", _params, socket) do
    Logger.info "Handling datasets..."

    payload = [%{"title" => "Sample.csv"}, %{"title" => "Another.csv"}]

    broadcast(socket, "datasets", %{datasets: payload})
    {:reply, :ok, socket}
  end
end
