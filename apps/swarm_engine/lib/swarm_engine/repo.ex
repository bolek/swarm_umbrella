defmodule SwarmEngine.Repo do
  alias __MODULE__
  use Ecto.Repo, otp_app: :swarm_engine

  def put_dataset(%SwarmEngine.DatasetNew{} = dataset) do
    changeset = dataset
    |> SwarmEngine.Repo.Schema.BaseDataset.changeset()

    case Repo.insert(changeset) do
      {:ok, _} ->
        {:ok, dataset}
      {:error, errors} ->
        {:error, errors}
    end
  end
end
