defmodule SwarmEngine.Endpoints.HTTPTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connector
  alias SwarmEngine.Endpoints.HTTP

  doctest SwarmEngine.Dataset

  def request(url) do
    url
    |> HTTP.create()
    |> Connector.request()
    |> Enum.to_list()
  end

  def request(url, options) do
    HTTP.create(url, options)
    |> Connector.request()
    |> Enum.to_list()
  end

  test "creating a HTTP source" do
    assert HTTP.create("some/path") == %HTTP{url: "some/path", options: []}
  end

  test "streaming a file" do
    assert [
             %SwarmEngine.Message{body: "requested"},
             %SwarmEngine.Message{body: "data"}
           ] = HTTPTest.request("http://example.com/file.csv")
  end

  test "streaming with headers" do
    assert [
             %SwarmEngine.Message{body: "requested"},
             %SwarmEngine.Message{body: "data"}
           ] = HTTPTest.request("http://url", [{:headers, [{"Authorization", "pass"}]}])
  end

  test "streaming with body" do
    assert [
             %SwarmEngine.Message{body: "requested"},
             %SwarmEngine.Message{body: "data"}
           ] = HTTPTest.request("http://url", [{:body, 123}])
  end

  test "when client fails" do
    assert_raise HTTP.Error, "requesting foo, got: {:error, :invalid_url}", fn ->
      HTTPTest.request("foo", [{:body, 123}])
    end
  end
end
