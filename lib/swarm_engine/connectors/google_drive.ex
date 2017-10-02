defmodule SwarmEngine.Connectors.GoogleDrive do
  defexception [:message]

  alias SwarmEngine.Connectors.HTTP

  @google_auth Application.get_env(:swarm_engine, :google_auth_client)
  @scope "https://www.googleapis.com/auth/drive.readonly"
  @endpoint "https://www.googleapis.com/drive/v3/"

  def create(params, options \\ []) do
    {__MODULE__, params, options}
  end

  def request(%{fileid: id}, _opts \\ []) do
    with  {:ok, %{token: token}} <- get_token(),
          url                    <- build_url(id),
          headers                <- build_headers(token)
    do
      HTTP.create(%{url: url}, [{:headers, headers}])
      |> HTTP.request()
    else
      sink ->
        raise __MODULE__, Kernel.inspect(sink)
    end
  end

  def metadata({__MODULE, %{file_id: id}, _opts} = source) do
    with  {:ok, %{token: token}}
            <- get_token(),
          url
            <- @endpoint <> "files/#{id}?fields=size,name,modifiedTime",
          headers
            <- build_headers(token),
          response
            <- get_metadata(%{url: url}, [{:headers, headers}])
    do
      {:ok, %{
        filename: get_filename(response),
        size: get_size(response),
        modified_at: get_modified_at(response),
        source: source
      }}
    else
      {:error, reason} -> {:error ,reason}
    end
  end

  def list(source) do
    {:error, :not_supported}
  end

  defp get_filename(%{"filename" => filename}), do: filename

  defp get_size(%{"size" => size}) do
    size
    |> Integer.parse
    |> elem(0)
  end

  defp get_modified_at(%{"modifiedTime" => modified_at}) do
    case  modified_at
          |> Calendar.DateTime.Parse.rfc3339_utc
    do
      {:ok, parsed} -> parsed
      _             -> nil
    end
  end

  defp get_token(), do: @google_auth.get_token(@scope)
  defp build_url(id), do: @endpoint <> "files/#{id}?alt=media"
  defp build_headers(token), do: [{'Authorization', 'Bearer #{token}'}]

  defp get_metadata(params, opts) do
    HTTP.create(params, opts)
    |> HTTP.request()
    |> Enum.to_list()
    |> Enum.join()
    |> Poison.Parser.parse!
  end
end
