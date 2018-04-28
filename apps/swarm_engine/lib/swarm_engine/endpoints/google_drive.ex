defmodule SwarmEngine.Endpoints.GoogleDrive do
  alias __MODULE__

  @type t :: %__MODULE__{file_id: integer}

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "GoogleDrive")
    field(:file_id, :integer)
  end

  def changeset(%GoogleDrive{} = file, %GoogleDrive{} = new) do
    file
    |> change(Map.from_struct(new))
  end

  def changeset(%GoogleDrive{} = file, attrs) do
    file
    |> cast(attrs, ~w(file_id))
    |> validate_required([:file_id])
  end

  def create(file_id) do
    %GoogleDrive{file_id: file_id}
  end

  defimpl SwarmEngine.Consumable do
    alias SwarmEngine.Consumer
    alias SwarmEngine.Resource
    alias SwarmEngine.Endpoints.{HTTP, GoogleDrive.Utils}

    @spec metadata(GoogleDrive.t()) :: {:ok, Resource.t()} | {:error, any}
    def metadata(%GoogleDrive{file_id: id} = source) do
      with {:ok, %{token: token}} <- Utils.get_token(),
           url <- Utils.endpoint() <> "files/#{id}?fields=size,name,modifiedTime",
           headers <- Utils.build_headers(token),
           response <- Utils.get_metadata(url, [{:headers, headers}]) do
        {:ok,
         %Resource{
           name: Utils.get_filename(response),
           size: Utils.get_size(response),
           modified_at: Utils.get_modified_at(response),
           source: source
         }}
      else
        {:error, reason} -> {:error, reason}
      end
    end

    @spec stream(GoogleDrive.t()) :: Enumerable.t()
    def stream(%GoogleDrive{file_id: id}) do
      with {:ok, %{token: token}} <- Utils.get_token(),
           url <- Utils.build_url(id),
           headers <- Utils.build_headers(token) do
        HTTP.create(url, [{:headers, headers}])
        |> Consumer.stream()
      else
        sink ->
          raise GoogleDrive.Error, Kernel.inspect(sink)
      end
    end
  end
end

defimpl SwarmEngine.Connector, for: SwarmEngine.Endpoints.GoogleDrive do
  alias SwarmEngine.{Consumer, Resource}

  @spec list(GoogleDrive.t()) :: {:ok, list(Resource.t())} | {:error, any}
  def list(source) do
    case Consumer.metadata(source) do
      {:ok, resource} ->
        {:ok, [resource]}

      {:error, error} ->
        {:error, error}
    end
  end
end
