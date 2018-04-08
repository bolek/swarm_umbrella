defmodule SwarmEngine.Resource do
  alias SwarmEngine.{Resource}

  use Ecto.Schema
  import Ecto.Changeset

  @enforce_keys [:name, :size, :modified_at, :source]
  defstruct [:name, :size, :modified_at, :source]
end
