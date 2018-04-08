defmodule SwarmEngine.Repo do
  alias __MODULE__
  alias SwarmEngine.Repo.Schema.Dataset, as: DatasetSchema

  use Ecto.Repo, otp_app: :swarm_engine
  import Ecto.Query, only: [from: 2]

  def set_utc(conn) do
    Postgrex.query!(conn, "SET TIME ZONE UTC;", [])
  end

  def put_dataset(%SwarmEngine.DatasetNew{} = dataset) do
    changeset =
      (get_raw_dataset(dataset.id) || %DatasetSchema{})
      |> DatasetSchema.changeset(dataset)

    case Repo.insert(changeset) do
      {:ok, new_dataset} ->
        {:ok, Map.put(dataset, :id, new_dataset.id)}

      {:error, %{errors: errors}} ->
        {:error, errors}
    end
  end

  def put_dataset(%SwarmEngine.Dataset{} = dataset) do
    changeset =
      get_raw_dataset(dataset.id)
      |> DatasetSchema.changeset(dataset)

    case Repo.update(changeset) do
      {:ok, _} ->
        {:ok, dataset}

      {:error, %{errors: errors}} ->
        {:error, errors}
    end
  end

  def get_dataset(id) do
    case get_raw_dataset(id) do
      nil ->
        nil

      %{status: :new} = dataset ->
        %SwarmEngine.DatasetNew{
          id: dataset.id,
          name: dataset.name,
          source: dataset.source,
          decoder: dataset.decoder
        }

      %{status: :active} = dataset ->
        %SwarmEngine.Dataset{
          id: dataset.id,
          name: dataset.name,
          tracker: %SwarmEngine.Tracker{
            source: dataset.tracker.source,
            store: dataset.tracker.store,
            resources: build_resources(dataset.tracker.resources)
          },
          decoder: dataset.decoder,
          store: dataset.store
        }
    end
  end

  defp get_raw_dataset(nil), do: nil

  defp get_raw_dataset(id) do
    from(d in DatasetSchema, preload: [tracker: :resources]) |> Repo.get(id)
  end

  defp build_resources(tracker_resources) do
    tracker_resources
    |> Enum.map(fn r ->
      struct(SwarmEngine.Resource, Map.from_struct(r))
    end)
    |> MapSet.new()
  end
end
