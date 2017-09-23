defmodule SwarmEngine.Connectors.HTTP do
  @http Application.get_env(:swarm_engine, :http_client)

  defmodule Error do
    alias __MODULE__

    defexception [:message]

    def exception({url, reason}) do
      msg = "requesting #{url}, got: #{Kernel.inspect(reason)}"
      %Error{message: msg}
    end

    def exception(url) do
      msg = "error when requesting #{url}"
      %Error{message: msg}
    end
  end

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
        {client, url}
      sink ->
        raise Error, {url, sink}
    end
  end

  defp continue_download({client, url}) do
    case @http.stream(client) do
      {:ok, data} ->
        {[data], {client, url}}
      :done ->
        # IO.puts "No more data"
        {:halt, {client, url}}
      _ ->
        raise Error, url
    end
  end

  defp finish_download({_client, _url}) do
  end
end
