defmodule SwarmEngine.Connectors.HTTPTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connectors.HTTP

  doctest SwarmEngine.Dataset

  def request(params) do
    params
    |> HTTP.create()
    |> HTTP.request()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  def request(params, options) do
    HTTP.create(params, options)
    |> HTTP.request
    |> Enum.to_list
    |> Enum.join(" ")
  end

  test "creating a HTTP source" do
    assert HTTP.create(%{url: "some/path"}) ==
      {HTTP, %{url: "some/path"}, []}
  end

  test "streaming a file" do
    assert ~s("requested" :get "http://example.com/file.csv" [] []) =
      HTTPTest.request(%{url: "http://example.com/file.csv"})
  end

  test "streaming with headers" do
    assert ~s("requested" :get "http://url" [{"Authorization", "pass"}] [headers: [{\"Authorization\", \"pass\"}]]) =
      HTTPTest.request(%{url: "http://url"}, [{:headers, [{"Authorization", "pass"}]}])
  end

  test "streaming with body" do
    assert ~s("requested" :get "http://url" [] [body: 123]) =
      HTTPTest.request(%{url: "http://url"}, [{:body, 123}])
  end

  test "when client fails" do
    assert_raise HTTP.Error, "requesting foo, got: {:error, :invalid_url}", fn ->
      HTTPTest.request(%{url: "foo"}, [{:body, 123}])
    end
  end
end
