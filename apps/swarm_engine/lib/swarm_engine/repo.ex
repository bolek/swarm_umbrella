defmodule SwarmEngine.Repo do
  alias __MODULE__
  alias SwarmEngine.Repo.Schema.BaseDataset

  use Ecto.Repo, otp_app: :swarm_engine

  def put_dataset(%SwarmEngine.DatasetNew{} = dataset) do
    changeset = dataset
    |> BaseDataset.changeset()

    case Repo.insert(changeset) do
      {:ok, _} ->
        {:ok, dataset}
      {:error, errors} ->
        {:error, errors}
    end
  end

  def get_dataset(id) do
    case Repo.get(BaseDataset, id) do
      nil ->
        nil
      dataset ->
        %SwarmEngine.DatasetNew{
          id: dataset.id,
          name: dataset.name,
          source: dataset.source,
          decoder: dataset.decoder
        }
    end
  end
end
