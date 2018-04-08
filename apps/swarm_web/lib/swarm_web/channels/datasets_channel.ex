defmodule SwarmWeb.DatasetsChannel do
  use Phoenix.Channel

  require Logger

  def join("datasets", _, socket), do: {:ok, socket}

  def handle_in("fetch", _params, socket) do
    Logger.info("Handling datasets...")

    payload =
      SwarmWeb.Api.DatasetView.render("index.json", %{
        datasets: SwarmEngine.list_datasets()
      })

    broadcast(socket, "datasets", IO.inspect(payload))
    {:reply, :ok, socket}
  end

  def handle_in("track", params, socket) do
    Logger.info("Handling track new dataset")

    id = SwarmEngine.Util.UUID.generate()

    IO.inspect(params)

    {:ok, _} =
      SwarmEngine.DatasetSupervisor.activate_dataset(%{
        id: id,
        name: params["msg"]["name"],
        source: params["msg"]["source"],
        decoder: params["msg"]["decoder"]
      })

    payload =
      SwarmWeb.Api.DatasetView.render("index.json", %{
        datasets: SwarmEngine.list_datasets()
      })

    broadcast(socket, "datasets", payload)

    {:reply, :ok, socket}
  end
end
