defmodule SwarmEngine.Connectors.HTTPTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connector
  alias SwarmEngine.Connectors.HTTP

  doctest SwarmEngine.Dataset

  def request(url) do
    url
    |> HTTP.create()
    |> Connector.request()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  def request(url, options) do
    HTTP.create(url, options)
    |> Connector.request
    |> Enum.to_list
    |> Enum.join(" ")
  end

  test "creating a HTTP source" do
    assert HTTP.create("some/path") ==
      %HTTP{url: "some/path", options: []}
  end

  test "streaming a file" do
    assert ~s("requested" :get "http://example.com/file.csv" [] []) =
      HTTPTest.request("http://example.com/file.csv")
  end

  test "streaming with headers" do
    assert ~s("requested" :get "http://url" [{"Authorization", "pass"}] [headers: [{\"Authorization\", \"pass\"}]]) =
      HTTPTest.request("http://url", [{:headers, [{"Authorization", "pass"}]}])
  end

  test "streaming with body" do
    assert ~s("requested" :get "http://url" [] [body: 123]) =
      HTTPTest.request("http://url", [{:body, 123}])
  end

  test "when client fails" do
    assert_raise HTTP.Error, "requesting foo, got: {:error, :invalid_url}", fn ->
      HTTPTest.request("foo", [{:body, 123}])
    end
  end
end
