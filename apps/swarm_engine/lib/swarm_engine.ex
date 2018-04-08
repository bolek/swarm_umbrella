defmodule SwarmEngine do
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

  def list_datasets(), do: SwarmEngine.Repo.list_datasets()

  def get_dataset(id), do: SwarmEngine.Repo.get_dataset(id)
end
