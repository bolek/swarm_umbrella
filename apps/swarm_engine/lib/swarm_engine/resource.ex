defmodule SwarmEngine.Resource do
  alias SwarmEngine.{Connector}

  @type t :: %__MODULE__{
    name: String.t,
    size: integer,
    modified_at: DateTime.t,
    source: Connector.t
  }

  defstruct [:name, :size, :modified_at, :source]
end
