defmodule SwarmWeb.Api.DatasetController do
  use SwarmWeb, :controller

  alias SwarmEngine
  alias SwarmEngine.{DatasetNew}

  action_fallback(SwarmWeb.FallbackController)

  def index(conn, _params) do
    datasets = SwarmEngine.list_datasets()
    render(conn, "index.json", datasets: datasets)
  end

  def create(conn, %{"dataset" => dataset_params}) do
    with {:ok, %DatasetNew{} = dataset, _} <-
           SwarmEngine.DatasetFactory.build_async(dataset_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", dataset_path(conn, :show, dataset))
      |> render("show.json", dataset: dataset)
    end
  end

  def show(conn, %{"id" => id}) do
    case SwarmEngine.get_dataset(id) do
      nil ->
        send_resp(conn, :not_found, "")

      dataset ->
        render(conn, "show.json", dataset: dataset)
    end
  end
end
