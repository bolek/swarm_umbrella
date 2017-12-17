defmodule SwarmWeb.DatasetsChannel do
  use Phoenix.Channel

  require Logger

  def join("datasets", _, socket), do: {:ok, socket}

  def handle_in("fetch", _params, socket) do
    Logger.info "Handling datasets..."

    payload = Swarm.Etl.list_datasets()
      |> Enum.map(&(Map.take(&1, [:name, :decoder])))
      |> Enum.map(&(Map.put(&1, :url, nil)))

    IO.inspect(payload)

    broadcast(socket, "datasets", %{datasets: payload})
    {:reply, :ok, socket}
  end

  def handle_in("track", params, socket) do
    Logger.info "Handling track new dataset"

    id = SwarmEngine.Util.UUID.generate

    IO.inspect(id)

    {:ok, pid} = SwarmEngine.DatasetSupervisor.activate_dataset(%{
      id: id,
      name: params["msg"]["title"],
      source: %SwarmEngine.Connectors.LocalFile{path: params["msg"]["source"]["path"]},
      decoder: SwarmEngine.Decoders.CSV.create [separator: params["msg"]["format"]["separator"]]
    })

    broadcast(socket, "datasets", %{datasets: [:sys.get_state(pid)]})

    {:reply, :ok, socket}
  end
end
