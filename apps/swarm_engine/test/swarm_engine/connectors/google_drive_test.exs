defmodule SwarmEngine.Connectors.GoogleDriveTest do
  use ExUnit.Case, async: true

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
    assert GoogleDrive.create("123abc") == %GoogleDrive{file_id: "123abc"}
  end

  test "streaming a file from GoogleDrive" do
    source = GoogleDrive.create("1234abc")

    assert [%SwarmEngine.Message{body: "requested"}, %SwarmEngine.Message{body: "data"}] =
             Enum.to_list(Connector.request(source))
  end
end
