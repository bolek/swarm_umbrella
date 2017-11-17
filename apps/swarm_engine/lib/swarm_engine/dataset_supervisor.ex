defmodule SwarmEngine.DatasetSupervisor do
  use Supervisor

  alias SwarmEngine.Datasets.CSV

  def start_link(_options), do:
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do:
    Supervisor.init([CSV], strategy: :simple_one_for_one)

  def activate_dataset(params) do
    Supervisor.start_child(__MODULE__, [params])
  end

  def deactivate_dataset(id) do
    Supervisor.terminate_child(__MODULE__, pid_from_id(id))
  end

  defp pid_from_id(id) do id
    |> CSV.via_tuple()
    |> GenServer.whereis()
  end
end
