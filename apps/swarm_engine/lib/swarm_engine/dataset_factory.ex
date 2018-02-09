defmodule SwarmEngine.DatasetFactory do
  alias SwarmEngine.{Connectors.LocalDir, Dataset, DatasetStore, Decoder, Decoders, Tracker}

  @tracker_store %LocalDir{path: "/tmp/swarm_engine_store/"}

  def build(name, source, decoder \\ Decoder.create(Decoders.CSV.create())) do
    with tracker <- initialize_tracker(source),
      {:ok, store} <- initialize_store(name, tracker, decoder)
    do
      {:ok, %Dataset{
        id: SwarmEngine.Util.UUID.generate,
        name: name,
        tracker: tracker,
        store: store,
        decoder: decoder
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
      store_name <- gen_store_name(name)
    do
      DatasetStore.create(%{name: store_name, columns: cols})
    else
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp gen_store_name(name), do:
    name |> String.downcase() |> String.replace(~r/\s+/, "_")
end
