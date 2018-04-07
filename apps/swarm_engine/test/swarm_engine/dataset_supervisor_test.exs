defmodule SwarmEngine.DatasetSupervisorTest do
  use SwarmEngine.DataCase

  alias SwarmEngine.DatasetSupervisor, as: DS

  setup do
    on_exit(fn ->
      DS.deactivate_all()
    end)

    :ok
  end

  @dataset_new %SwarmEngine.DatasetNew{
    id: "247a3e2d-70c0-4713-a0cc-7124e20e5a88",
    name: "goofy",
    source:
      SwarmEngine.Connectors.StringIO.create(
        "list",
        "col_4,col_5\nABC,def\nKLM,edd\n"
      ),
    decoder: SwarmEngine.Decoders.CSV.create()
  }

  test "activate_dataset when passing a new dataset" do
    assert {:ok, pid} = DS.activate_dataset(@dataset_new)

    assert @dataset_new == :sys.get_state(pid)
  end

  test "activate_dataset when passing only params" do
    assert {:ok, pid} =
             DS.activate_dataset(%{
               id: "247a3e2d-70c0-4713-a0cc-7124e20e5a88",
               name: "goofy",
               source:
                 SwarmEngine.Connectors.StringIO.create(
                   "list",
                   "col_4,col_5\nABC,def\nKLM,edd\n"
                 ),
               decoder: SwarmEngine.Decoders.CSV.create()
             })

    assert @dataset_new == :sys.get_state(pid)
  end

  test "activate_dataset twice raises error" do
    DS.activate_dataset(@dataset_new)

    assert {:error, [id: {"has already been taken", []}]} = DS.activate_dataset(@dataset_new)
  end

  test "deactivate_dataset when passing existing id" do
    DS.activate_dataset(@dataset_new)
    assert %{active: 1, workers: 1} = Supervisor.count_children(DS)
    DS.deactivate_dataset(@dataset_new.id)
    assert %{active: 0, workers: 0} = Supervisor.count_children(DS)
  end

  test "deactivate_dataset when passing inexistent id" do
    DS.activate_dataset(@dataset_new)
    assert %{active: 1, workers: 1} = Supervisor.count_children(DS)

    assert {:error, :simple_one_for_one} =
             DS.deactivate_dataset("247a3e2d-aaaa-aaaa-aaaa-7124e20e5a88")

    assert %{active: 1, workers: 1} = Supervisor.count_children(DS)
  end

  test "deactivate_all" do
    DS.activate_dataset(@dataset_new)
    assert %{active: 1, workers: 1} = Supervisor.count_children(DS)
    DS.deactivate_all()
    assert %{active: 0, workers: 0} = Supervisor.count_children(DS)
  end
end
