defmodule SwarmEngine.Connectors.HTTP.Helpers do
  alias SwarmEngine.Util.UUID

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
    headers
    |> extract_header("Content-Length")
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

  defp parse_content_length(""), do: nil
  defp parse_content_length(i), do: Integer.parse(i) |> elem(0)

  defp map_content_type("application/zip"), do: 'zip'
  defp map_content_type("text/html"), do: 'html'
  defp map_content_type("text/csv"), do: 'csv'
  defp map_content_type("application/json"), do: 'json'
  defp map_content_type("text/json"), do: 'json'
  defp map_content_type(_), do: nil
end
