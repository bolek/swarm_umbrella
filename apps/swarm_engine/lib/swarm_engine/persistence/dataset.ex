defmodule SwarmEngine.Persistence.Dataset do
  alias SwarmEngine.Serializer

  def serialize(%{name: name, decoder: decoder, store: store, tracker: tracker}) do
    %{
      name: name,
      decoder: Serializer.encode!(decoder),
      store: Serializer.encode!(store),
      tracker: Serializer.encode!(tracker)
    }
  end

  def deserialize(%{name: name, decoder: decoder, store: store, tracker: tracker}) do
    %SwarmEngine.Dataset{
      name: name,
      decoder: Serializer.decode!(decoder),
      store: Serializer.decode!(store),
      tracker: Serializer.decode!(tracker)
    }
  end
end
