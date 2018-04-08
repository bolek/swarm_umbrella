defmodule SwarmEngine.DatasetSupervisor do
  use Supervisor

  alias SwarmEngine.Dataset

  # Client API

  def start_link(_options), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def activate_dataset(id) when is_binary(id) do
    Supervisor.start_child(__MODULE__, [id])
  end

  def activate_dataset(%{name: _, source: _} = attrs) do
    case SwarmEngine.DatasetFactory.create(attrs) do
      {:ok, dataset} ->
        activate_dataset(dataset.id)

      {:error, errors} ->
        {:error, errors}
    end
  end

  def deactivate_dataset(id) do
    Supervisor.terminate_child(__MODULE__, pid_from_id(id))
  end

  def deactivate_all() do
    Supervisor.which_children(__MODULE__)
    |> Enum.each(fn {_, pid, :worker, _} ->
      Supervisor.terminate_child(__MODULE__, pid)
    end)
  end

  def get_or_activate(id) do
    case pid_from_id(id) do
      nil ->
        activate_dataset(id)

      pid ->
        {:ok, pid}
    end
  end

  # Server API

  def init(:ok), do: Supervisor.init([Dataset], strategy: :simple_one_for_one)

  # Private

  defp pid_from_id(id) do
    id
    |> Dataset.via_tuple()
    |> GenServer.whereis()
  end
end
