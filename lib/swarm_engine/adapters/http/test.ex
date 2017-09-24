defmodule SwarmEngine.Adapters.HTTP.Test do
  def get(term, url, headers, body, opts) do
    with  {:ok, _} <-
            validate_http_request(url),
          content <-
            gen_content(term, url, headers, body, opts),
          {:ok, pid} <-
            Agent.start_link(fn -> content end)
    do
      {:ok, 200, [{"Content-Length", "20000"}], pid}
    else
      boom ->
        boom
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

  defp validate_http_request(url) do
    case String.starts_with?(url, "http") do
      false ->
        {:error, :invalid_url}
      true ->
        {:ok, url}
    end
  end

  defp gen_content(term, url, headers, _body, opts) do
    ["requested", term, url, headers, opts]
      |> Enum.map(&(Kernel.inspect(&1)))
  end
end
