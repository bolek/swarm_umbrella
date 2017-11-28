defmodule SwarmWeb.DatasetsChannel do
  use Phoenix.Channel

  require Logger

  def join("datasets", _, socket), do: {:ok, socket}

  def handle_in("fetch", _params, socket) do
    Logger.info "Handling datasets..."

    payload =[
      %{"title" => "Sample.csv", "url" => "google.com", source: %{ type: "LocalFile", path: "abc"}},
      %{"title" => "Another.csv", "url" => nil}
    ]

    broadcast(socket, "datasets", %{datasets: payload})
    {:reply, :ok, socket}
  end

  def handle_in("track", params, socket) do
    Logger.info "Handling track new dataset"

    id = SwarmEngine.Util.UUID.generate

    IO.inspect(id)

    {:ok, _} = SwarmEngine.DatasetSupervisor.activate_dataset(%{
      id: id,
      name: params["msg"]["title"],
      source: %SwarmEngine.Connectors.LocalFile{path: params["msg"]["source"]["path"]},
      decoder: SwarmEngine.Decoders.CSV.create [separator: params["msg"]["format"]["separator"]]
    })

    broadcast(socket, "datasets", %{datasets: [params["msg"]]})

    {:reply, :ok, socket}
  end
end
