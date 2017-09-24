defmodule SwarmEngine.Adapters.GoogleAuth.Test do
  def get_token(_scope), do: {:ok, %{token: "abctoken"}}
end
