defmodule SwarmEngine.Connectors.HTTP do
  alias __MODULE__

  @type t :: %__MODULE__{url: String.t(), options: keyword}
  defstruct [:url, :options]

  @spec create(String.t(), keyword) :: HTTP.t()
  def create(url, options \\ []) do
    %HTTP{url: url, options: options}
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Connectors.HTTP do
  alias SwarmEngine.Connectors.HTTP
  alias SwarmEngine.Resource

  @spec list(Connector.t()) :: {:ok, list(Resource.t())} | {:error, any}
  def list(source) do
    case metadata(source) do
      {:ok, resource} ->
        {:ok, [resource]}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec metadata(HTTP.t()) :: {:ok, Resource.t()}
  def metadata(%HTTP{url: url, options: opts} = source) do
    {headers, body, opts} = HTTP.Utils.initialize_opts(opts)

    with {:ok, 200, response_headers} <-
           HTTP.Utils.http().request(:head, url, headers, body, opts),
         filename <- HTTP.Utils.get_filename(url, response_headers),
         size <- HTTP.Utils.get_file_size(response_headers),
         modified_at <- HTTP.Utils.get_modified_at(response_headers) do
      {:ok,
       %Resource{
         name: filename,
         size: size,
         modified_at: modified_at,
         source: source
       }}
    else
      sink ->
        {:error, {url, sink}}
    end
  end

  @spec request(HTTP.t()) :: Enumerable.t()
  def request(%HTTP{url: url, options: opts} = endpoint) do
    {headers, body, opts} = HTTP.Utils.initialize_opts(opts)

    Stream.resource(
      fn -> HTTP.Utils.begin_download(:get, url, headers, body, opts) end,
      &HTTP.Utils.continue_download/1,
      &HTTP.Utils.finish_download/1
    )
    |> Stream.map(fn i ->
      SwarmEngine.Message.create(i, %{size: byte_size(i), endpoint: endpoint})
    end)
  end
end
