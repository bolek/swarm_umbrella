defmodule SwarmEngine.Endpoints.GoogleDriveTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Consumer
  alias SwarmEngine.Endpoints.GoogleDrive

  def request(file_id) do
    file_id
    |> GoogleDrive.create()
    |> Consumer.stream()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  test "creating a GoogleDrive source" do
    assert GoogleDrive.create("123abc") == %GoogleDrive{file_id: "123abc"}
  end

  test "streaming a file from GoogleDrive" do
    source = GoogleDrive.create("1234abc")

    assert [%SwarmEngine.Message{body: "requested"}, %SwarmEngine.Message{body: "data"}] =
             Enum.to_list(Consumer.stream(source))
  end
end
