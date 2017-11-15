defmodule SwarmEngine.Connectors.HTTP.Utils do
  alias SwarmEngine.Util.UUID
  alias SwarmEngine.Connectors.HTTP.Error

  @http Application.get_env(:swarm_engine, :http_client)

  def http, do: @http

  def initialize_opts(opts) do
    headers = extract_value(opts, :headers, [])
    body = extract_value(opts, :body, "")

    {headers, body, opts}
  end

  def begin_download(term, url, req_headers, body, opts) do
    case @http.request(term, url, req_headers, body, opts) do
      {:ok, 200, _headers, client} ->
        {client, url}
      sink ->
        raise Error, {url, sink}
    end
  end

  def continue_download({client, url}) do
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

  def finish_download({_client, _url}) do
  end

  def get_filename(url, headers) do
    basename = url_basename(url)
    get_filename(basename, has_extension?(basename), get_content_type(headers))
  end

  # When url has filename with extension use that as filename
  defp get_filename(filename, true, _), do: filename

  # When url does not have filename and we don't have content type
  defp get_filename(_, false, nil), do: "#{UUID.generate()}"

  # When we have content type
  defp get_filename(_, false, type),do: "#{UUID.generate()}.#{type}"

  def get_file_size(headers) do
    ["Content-Length", "Content-Range"]
    |> Enum.map(&({&1, extract_header(headers, &1)}))
    |> Enum.filter(fn {_, v} -> v != "" end)
    |> List.first
    |> parse_content_length()
  end

  def get_modified_at(headers) do
    case headers
    |> extract_value("Last-Modified", "")
    |> Calendar.DateTime.Parse.httpdate do
      {:ok, datetime} -> datetime
      {:bad_format, _}     -> nil
    end
  end

  def extract_value(opts, key, default) do
    opts
    |> List.keyfind(key, 0, {nil, default})
    |> elem(1)
  end

  defp extract_header(headers, header) do
    headers
    |> extract_value(header, "")
    |> String.downcase()
  end

  defp get_content_type(headers) do
    headers
    |> extract_header("Content-Type")
    |> String.downcase()
    |> String.split(";")
    |> List.first
    |> map_content_type
  end

  defp url_basename(url) do
    url
    |> URI.parse
    |> Map.get(:path, "")
    |> Path.basename
  end

  def has_extension?(basename) do
    basename
    |> Path.extname
    |> valid_extension?
  end

  defp valid_extension?(""), do: false
  defp valid_extension?(_), do: true

  defp parse_content_length(nil), do: nil
  defp parse_content_length({"Content-Length", v}), do: Integer.parse(v) |> elem(0)
  defp parse_content_length({"Content-Range", v}) do
    ~r/bytes (?<range_start>\d+)-(?<range_end>\d+)\/(?<size>\d+)/
    |> Regex.named_captures(v)
    |> Map.get("size")
    |> Integer.parse()
    |> elem(0)
  end

  defp map_content_type("application/zip"), do: 'zip'
  defp map_content_type("text/html"), do: 'html'
  defp map_content_type("text/csv"), do: 'csv'
  defp map_content_type("application/json"), do: 'json'
  defp map_content_type("text/json"), do: 'json'
  defp map_content_type(_), do: nil
end
