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
    changeset = %Dataset{store: nil}
    |> Dataset.new_changeset(attrs)

    case changeset.valid? do
      true ->
        changeset
        |> Ecto.Changeset.apply_changes
      false ->
        changeset
    end
    |> Repo.insert

  end

  def list_datasets(), do:
    from(d in Dataset, preload: [:tracker]) |> Repo.all

  def get_dataset!(id), do:
    from(d in Dataset, preload: [:tracker]) |> Repo.get!(id)

  def delete_dataset(%Dataset{} = dataset), do:
    Repo.delete(dataset)

  def update_dataset(%Dataset{} = dataset, attrs) do
    dataset
    |> Dataset.update_changeset(attrs)
    |> Repo.update()
  end
end
