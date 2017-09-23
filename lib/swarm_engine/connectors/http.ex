defmodule SwarmEngine.Connectors.HTTP do
  @http Application.get_env(:swarm_engine, :http_client)

  def get(%{url: url}, opts \\ []) do
    {term, headers, body, opts} = initialize_opts(opts)

    Stream.resource(fn -> begin_download(term, url, headers, body, opts) end,
                    &continue_download/1,
                    &finish_download/1)
  end

  defp initialize_opts(opts) do
    term = extract_option(opts, :term, :get)
    headers = extract_option(opts, :headers, [])
    body = extract_option(opts, :body, "")

    {term, headers, body, opts}
  end

  defp extract_option(opts, key, default) do
    Keyword.pop_first(opts, key, default) |> elem(0)
  end

  defp begin_download(term, url, req_headers, body, opts) do
    case @http.get(term, url, req_headers, body, opts) do
      {:ok, 200, _headers, client} ->
        client
      all ->
        {:error, all}
    end
  end

  defp continue_download(client) do
    case @http.stream(client) do
      {:ok, data} ->
        {[data], client}
      :done ->
        # IO.puts "No more data"
        {:halt, client}
      {:error, reason} ->
        raise reason
    end
  end

  defp finish_download(_client) do
  end
end
