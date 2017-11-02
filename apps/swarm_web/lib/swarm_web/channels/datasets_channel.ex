defmodule SwarmWeb.DatasetsChannel do
  use Phoenix.Channel


  require Logger

  def join("datasets", _, socket), do: {:ok, socket}

  def handle_in("datasets:fetch", params, socket) do
    Logger.info "Handling datasets..."


    {:reply, {:ok, "booom"}, socket}
  end
end
