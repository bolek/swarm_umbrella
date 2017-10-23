defmodule SwarmEngine.Connectors.HTTP.UtilsTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.HTTP.Utils

  test "get_filename when passed url with filename" do
    url = "http://google.drive.com/filename.zip"
    headers = []

    assert "filename.zip" =
      Utils.get_filename(url, headers)
  end

  test "get_filename when passed url without extension" do
    url = "http://google.drive.com/filename"
    headers = []

    refute "filename" ==
      Utils.get_filename(url, headers)
  end

  test "get_filename when passed url without extension but have content-type header" do
    url = "http://google.drive.com/filename"
    headers = [{"Content-Type", "application/zip"}]

    assert Regex.match?(~r/.*\.zip$/, Utils.get_filename(url, headers))
  end

  test "get_filename when passed url with extension and content-type header" do
    url = "http://google.drive.com/filename.csv"
    headers = [{"Content-Type", "application/zip"}]

    assert "filename.csv" = Utils.get_filename(url, headers)
  end

  test "get_file_size when Content-Length provided" do
    headers = [{"Content-Length", "12345"}]

    assert 12345 = Utils.get_file_size(headers)
  end

  test "get_file_size when Content-Length not provided" do
    headers = []

    assert nil == Utils.get_file_size(headers)
  end

  test "get_file_size when Content-Range provided" do
    headers = [{"Content-Range", "bytes 0-654/654"}]

    assert 654 == Utils.get_file_size(headers)
  end
end
