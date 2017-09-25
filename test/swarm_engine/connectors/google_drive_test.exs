defmodule SwarmEngine.Connectors.GoogleDriveTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connectors.GoogleDrive

  def request(params) do
    GoogleDrive.request(params)
      |> Enum.to_list()
      |> Enum.join(" ")
  end

  test "streaming a file from dropbox" do
    assert ~s("requested" :get "https://www.googleapis.com/drive/v3/files/123abc?alt=media" [{'Authorization', 'Bearer abctoken'}] [headers: [{'Authorization', 'Bearer abctoken'}]]) =
      GoogleDriveTest.request(%{fileid: "123abc"})
  end
end
