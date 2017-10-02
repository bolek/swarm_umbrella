defmodule SwarmEngine.Tracker do
  alias SwarmEngine.Connector
  alias __MODULE__

  defstruct [:source, :store, :resources]

  def create(source, store) do
    %Tracker{source: source, store: store, resources: MapSet.new()}
  end

  def synced?(tracker, resource) do
    find(tracker, resource) != nil
  end

  def find(tracker, %{filename: filename, size: size, modified_at: modified_at}) do
    tracker.resources
    |> Enum.find(fn(x) ->
                    x.filename == filename
                    && x.size == size
                    && x.modified_at == modified_at
                 end
                )
  end

  def sync(%Tracker{source: source} = tracker) do
    {:ok, resources} = Connector.list(source)

    resources
    |> Enum.reduce(tracker, fn(x, tracker) ->
                              Tracker.add(tracker, x)
                            end)
  end

  def add(tracker, resource) do
    case Tracker.find(tracker, resource) do
      nil ->
        {:ok, new} = Connector.store(resource, tracker.store)
        put_in(tracker.resources, MapSet.put(tracker.resources, new))
      _ ->
        tracker
    end
  end
end
