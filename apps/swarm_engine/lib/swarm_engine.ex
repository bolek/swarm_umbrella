defmodule SwarmEngine do
  alias SwarmEngine.{Dataset, Repo}

  import Ecto.Query, only: [from: 2]

  @moduledoc """
  Documentation for SwarmEngine.
  """

  @doc """
  Hello world.

  ## Examples

      iex> SwarmEngine.hello
      :world

  """
  def hello do
    :world
  end

  def create_dataset(attrs \\ %{}) do
    %Dataset{store: nil}
    |> Dataset.changeset(attrs)
    |> Repo.insert()
  end

  def list_datasets(), do:
    from(d in Dataset, preload: [:tracker]) |> Repo.all

  def get_dataset!(id), do:
    from(d in Dataset, preload: [:tracker]) |> Repo.get(id)
end
