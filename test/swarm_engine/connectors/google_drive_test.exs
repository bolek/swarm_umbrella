defmodule SwarmEngine.Connectors.GoogleDriveTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connector
  alias SwarmEngine.Connectors.GoogleDrive

  def request(file_id) do
    file_id
    |> GoogleDrive.create()
    |> Connector.request()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  test "creating a GoogleDrive source" do
    assert GoogleDrive.create("123abc") ==
      %GoogleDrive{file_id: "123abc"}
  end

  test "streaming a file from dropbox" do
    assert ~s("requested" :get "https://www.googleapis.com/drive/v3/files/123abc?alt=media" [{'Authorization', 'Bearer abctoken'}] [headers: [{'Authorization', 'Bearer abctoken'}]]) =
      GoogleDriveTest.request("123abc")
  end
end
