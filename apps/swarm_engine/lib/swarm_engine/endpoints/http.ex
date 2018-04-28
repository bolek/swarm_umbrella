defmodule SwarmEngine.Endpoints.HTTP do
  alias __MODULE__
  alias SwarmEngine.Resource

  @type t :: %__MODULE__{url: String.t(), options: keyword}
  defstruct [:url, :options]

  @spec create(String.t(), keyword) :: HTTP.t()
  def create(url, options \\ []) do
    %HTTP{url: url, options: options}
  end

  defimpl SwarmEngine.Consumable do
    @spec metadata(HTTP.t()) :: {:ok, Resource.t()}
    def metadata(%HTTP{url: url, options: opts} = source) do
      {headers, body, opts} = HTTP.Utils.initialize_opts(opts)

      with {:ok, 200, response_headers, _} <-
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

    @spec stream(HTTP.t()) :: Enumerable.t()
    def stream(%HTTP{url: url, options: opts} = endpoint) do
      {headers, body, opts} = HTTP.Utils.initialize_opts(opts)

      with {:ok, resource} <- metadata(endpoint) do
        Stream.resource(
          fn -> HTTP.Utils.begin_download(:get, url, headers, body, opts) end,
          &HTTP.Utils.continue_download/1,
          &HTTP.Utils.finish_download/1
        )
        |> Stream.map(fn i ->
          SwarmEngine.Message.create(i, %{size: byte_size(i), resource: resource})
        end)
      else
        {:error, {url, sink}} -> raise SwarmEngine.Endpoints.HTTP.Error, {url, sink}
      end
    end
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Endpoints.HTTP do
  alias SwarmEngine.{Consumer, Consumable, Resource}

  @spec list(Consumable.t()) :: {:ok, list(Resource.t())} | {:error, any}
  def list(endpoint) do
    case Consumer.metadata(endpoint) do
      {:ok, resource} ->
        {:ok, [resource]}

      {:error, error} ->
        {:error, error}
    end
  end
end
