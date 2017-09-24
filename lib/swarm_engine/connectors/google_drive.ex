defmodule SwarmEngine.Connectors.GoogleDrive do
  defexception [:message]

  @google_auth Application.get_env(:swarm_engine, :google_auth_client)
  @scope "https://www.googleapis.com/auth/drive.readonly"
  @endpoint "https://www.googleapis.com/drive/v3/"

  def get(%{fileid: id}, _opts \\ []) do
    with  {:ok, %{token: token}} <- get_token(),
          url                    <- build_url(id),
          headers                <- build_headers(token)
    do
      SwarmEngine.Connectors.HTTP.get(%{url: url}, [{:headers, headers}])
    else
      sink ->
        raise __MODULE__, Kernel.inspect(sink)
    end
  end

  defp get_token(), do: @google_auth.get_token(@scope)
  defp build_url(id), do: @endpoint <> "files/#{id}?alt=media"
  defp build_headers(token), do: [{'Authorization', 'Bearer #{token}'}]
end
