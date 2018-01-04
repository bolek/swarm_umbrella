defmodule SwarmWeb.DatasetView do
  use SwarmWeb, :view
  alias SwarmWeb.DatasetView

  def render("index.json", %{datasets: datasets}) do
    %{data: render_many(datasets, DatasetView, "dataset.json")}
  end

  def render("show.json", %{dataset: dataset}) do
    %{data: render_one(dataset, DatasetView, "dataset.json")}
  end

  def render("dataset.json", %{dataset: dataset}) do
    %{id: dataset.id,
      name: dataset.name,
      decoder: dataset.decoder,
      tracker: dataset.tracker,
      url: nil
    }
  end
end
