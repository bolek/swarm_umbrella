defmodule SwarmEngine.Connectors.HTTP.HelpersTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.HTTP.Helpers

  test "get_filename when passed url with filename" do
    url = "http://google.drive.com/filename.zip"
    headers = []

    assert "filename.zip" =
      Helpers.get_filename(url, headers)
  end

  test "get_filename when passed url without extension" do
    url = "http://google.drive.com/filename"
    headers = []

    refute "filename" ==
      Helpers.get_filename(url, headers)
  end

  test "get_filename when passed url without extension but have content-type header" do
    url = "http://google.drive.com/filename"
    headers = [{"Content-Type", "application/zip"}]

    assert Regex.match?(~r/.*\.zip$/, Helpers.get_filename(url, headers))
  end

  test "get_filename when passed url with extension and content-type header" do
    url = "http://google.drive.com/filename.csv"
    headers = [{"Content-Type", "application/zip"}]

    assert "filename.csv" = Helpers.get_filename(url, headers)
  end

  test "get_file_size when Content-Length provided" do
    headers = [{"Content-Length", "12345"}]

    assert 12345 = Helpers.get_file_size(headers)
  end

  test "get_file_size when Content-Length not provided" do
    headers = []

    assert nil == Helpers.get_file_size(headers)
  end
end
