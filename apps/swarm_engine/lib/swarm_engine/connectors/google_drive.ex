defmodule SwarmEngine.Connectors.GoogleDrive do
  alias __MODULE__

  @type t :: %__MODULE__{file_id: integer}
  defstruct [:file_id]

  def create(file_id) do
    %GoogleDrive{file_id: file_id}
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Connectors.GoogleDrive do
  alias SwarmEngine.{Connector, Resource}
  alias SwarmEngine.Connectors.{GoogleDrive, HTTP}
  alias SwarmEngine.Connectors.GoogleDrive.Utils

  @spec list(GoogleDrive.t) :: {:ok, list(Resource.t)} | {:error, any}
  def list(source) do
    case metadata(source) do
      {:ok, resource} ->
        {:ok, [resource]}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec metadata(GoogleDrive.t) :: {:ok, Resource.t} | {:error, any}
  def metadata(%GoogleDrive{file_id: id} = source) do
    with  {:ok, %{token: token}}
            <- Utils.get_token(),
          url
            <- Utils.endpoint <> "files/#{id}?fields=size,name,modifiedTime",
          headers
            <- Utils.build_headers(token),
          response
            <- Utils.get_metadata(url, [{:headers, headers}])
    do
      {:ok, %Resource{
        name: Utils.get_filename(response),
        size: Utils.get_size(response),
        modified_at: Utils.get_modified_at(response),
        source: source
      }}
    else
      {:error, reason} -> {:error ,reason}
    end
  end

  @spec request(GoogleDrive.t) :: Enumerable.t
  def request(%GoogleDrive{file_id: id}) do
    with  {:ok, %{token: token}} <- Utils.get_token(),
          url                    <- Utils.build_url(id),
          headers                <- Utils.build_headers(token)
    do
      HTTP.create(url, [{:headers, headers}])
      |> Connector.request()
    else
      sink ->
        raise GoogleDrive.Error, Kernel.inspect(sink)
    end
  end
end
