defmodule SwarmEngine.DatasetFactory do
  alias SwarmEngine.{Connectors.LocalDir, Dataset, DatasetStore, Tracker}

  @tracker_store %LocalDir{path: "/tmp/swarm_engine_store/"}

  def create(attrs) do
    case SwarmEngine.DatasetNew.create_changeset(attrs) do
      %{valid?: true} = changeset ->
        changeset
        |> Ecto.Changeset.apply_changes()
        |> SwarmEngine.Repo.put_dataset()

      %{valid?: false} = changeset ->
        {:error, changeset}
    end
  end

  def build(attrs) do
    case create(attrs) do
      {:ok, dataset} ->
        initialize(dataset)

      {:error, any} ->
        {:error, any}
    end
  end

  def build_async(attrs) do
    case create(attrs) do
      {:ok, dataset} ->
        task = Task.async(fn -> initialize(dataset) end)
        {:ok, dataset, task}

      {:error, any} ->
        {:error, any}
    end
  end

  def initialize(%SwarmEngine.DatasetNew{} = new_dataset) do
    with tracker <- initialize_tracker(new_dataset.source),
         {:ok, store} <- initialize_store(new_dataset.id, tracker, new_dataset.decoder) do
      {:ok,
       %Dataset{
         id: new_dataset.id,
         name: new_dataset.name,
         tracker: tracker,
         store: store,
         decoder: new_dataset.decoder
       }}
    else
      {:error, e} -> {:error, e}
      any -> {:error, any}
    end
  end

  defp initialize_tracker(source) do
    source
    |> Tracker.create(@tracker_store)
    |> Tracker.sync()
  end

  defp initialize_store(name, tracker, decoder) do
    with {:ok, cols} <- Tracker.current_resource_columns(tracker, decoder),
         store_name <- gen_store_name(name) do
      DatasetStore.create(%{name: store_name, columns: cols})
    else
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp gen_store_name(name) do
    ("_" <> name)
    |> String.replace(~r/-/, "")
  end
end
