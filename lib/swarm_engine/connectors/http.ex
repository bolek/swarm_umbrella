defmodule SwarmEngine.Connectors.HTTP do
  alias __MODULE__.Helpers

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

  def request(%{url: url}, opts \\ []) do
    {headers, body, opts} = initialize_opts(opts)

    Stream.resource(fn -> begin_download(:get, url, headers, body, opts) end,
                    &continue_download/1,
                    &finish_download/1)
  end

  def request_metadata(%{url: url}, opts \\ []) do
    {headers, body, opts} = initialize_opts(opts)

    with  {:ok, 200, response_headers} <-
            @http.request(:head, url, headers, body, opts),
          filename <-
            Helpers.get_filename(url, response_headers),
          size <-
            Helpers.get_file_size(response_headers)
    do
      {:ok, %{filename: filename, size: size}}
    else
      sink ->
        {:error, {url, sink}}
    end
  end

  defp initialize_opts(opts) do
    headers = Helpers.extract_value(opts, :headers, [])
    body = Helpers.extract_value(opts, :body, "")

    {headers, body, opts}
  end

  defp begin_download(term, url, req_headers, body, opts) do
    case @http.request(term, url, req_headers, body, opts) do
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
