defmodule SwarmEngine.Adapters.HTTP.Test do
  def get(term, url, headers, body, opts) do
    content = ["requested", term, url, headers, opts]
      |> Enum.map(&(Kernel.inspect(&1)))

    case Agent.start_link fn -> content end do
      {:ok, pid } ->
        {:ok, 200, [{"Content-Length", "20000"}], pid}
      _ ->
        {:error, "Unable to connect to #{url}"}
    end
  end

  def stream(pid) do
    case Agent.get_and_update(pid, &(List.pop_at(&1 ,0))) do
      nil ->
        :done

      data ->
        {:ok, data}
    end
  end
end
