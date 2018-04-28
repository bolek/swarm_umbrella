defmodule SwarmEngine.Endpoints.GoogleDrive.Utils do
  alias SwarmEngine.Consumer
  alias SwarmEngine.Endpoints.HTTP

  @google_auth Application.get_env(:swarm_engine, :google_auth_client)
  @scope "https://www.googleapis.com/auth/drive.readonly"
  @endpoint "https://www.googleapis.com/drive/v3/"

  def endpoint, do: @endpoint

  def get_filename(%{"filename" => filename}), do: filename

  def get_size(%{"size" => size}) do
    size
    |> Integer.parse()
    |> elem(0)
  end

  def get_modified_at(%{"modifiedTime" => modified_at}) do
    case modified_at
         |> Calendar.DateTime.Parse.rfc3339_utc() do
      {:ok, parsed} -> parsed
      _ -> nil
    end
  end

  def get_token(), do: @google_auth.get_token(@scope)
  def build_url(id), do: @endpoint <> "files/#{id}?alt=media"
  def build_headers(token), do: [{'Authorization', 'Bearer #{token}'}]

  def get_metadata(params, opts) do
    HTTP.create(params, opts)
    |> Consumer.stream()
    |> Enum.to_list()
    |> Enum.join()
    |> Poison.Parser.parse!()
  end
end
