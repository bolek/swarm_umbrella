defmodule SwarmEngine.Tracker do
  alias SwarmEngine.{Tracker, Connector, Resource}

  defstruct [:source, :store, :resources]

  def create(source, store) do
    %Tracker{source: source, store: store, resources: MapSet.new()}
  end

  def synced?(tracker, resource) do
    find(tracker, resource) != nil
  end

  def find(tracker, %{name: name, size: size, modified_at: modified_at}) do
    tracker.resources
    |> Enum.find(fn(x) ->
                    x.name == name
                    && x.size == size
                    && x.modified_at == modified_at
                 end
                )
  end

  def find(tracker, %{version: version}) do
    case tracker.resources |> Enum.find(&(&1.modified_at == version)) do
      nil -> {:error, :not_found}
      resource -> {:ok, resource}
    end
  end

  def sync(%Tracker{source: source} = tracker) do
    {:ok, resources} = Connector.list(source)

    resources
    |> Enum.reduce(tracker, fn(x, tracker) ->
                              Tracker.add(tracker, x)
                            end)
  end

  def current(%Tracker{resources: resources}) do
    resources
    |> Enum.max_by(fn(%{modified_at: modified_at}) -> modified_at end, fn -> nil end)
  end

  def add(tracker, resource) do
    case Tracker.find(tracker, resource) do
      nil ->
        {:ok, new} = tracker.store.__struct__.store(resource, tracker.store)
        put_in(tracker.resources, MapSet.put(tracker.resources, new))
      _ ->
        tracker
    end
  end

  def from_map(%{"source" => source, "store" => store, "resources" => resources}) do
    from_map(%{source: source, store: store, resources: resources})
  end

  def from_map(%{} = m) do
    %Tracker{
      source: from_map_type(m.source),
      store: from_map_type(m.store),
      resources: (Enum.map(m.resources, &(Resource.from_map(&1))) |> Enum.into(MapSet.new))
    }
  end

  defp from_map_type(%{type: type} = x), do:
    type.from_map(x)

  defp from_map_type(%{"type" => type} = x) do
    Map.put(x, :type, String.to_existing_atom(type))
    |> from_map_type
  end
end

defimpl SwarmEngine.Mapable, for: SwarmEngine.Tracker do
  alias SwarmEngine.Tracker

  def to_map(%Tracker{} = t) do
    %{
      source: SwarmEngine.Mapable.to_map(t.source),
      store: SwarmEngine.Mapable.to_map(t.store),
      resources: Enum.map(t.resources, &(SwarmEngine.Mapable.to_map(&1)))
    }
  end
end
