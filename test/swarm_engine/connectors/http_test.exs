defmodule SwarmEngine.Connectors.HTTPTest do
  use ExUnit.Case, async: true

  alias __MODULE__
  alias SwarmEngine.Connectors.HTTP

  doctest SwarmEngine.Dataset

  def get(params) do
    HTTP.get(params)
      |> Enum.to_list()
      |> Enum.join(" ")
  end

  def get(params, options) do
    HTTP.get(params, options)
      |> Enum.to_list()
      |> Enum.join(" ")
  end

  test "streaming a file" do
    assert ~s("requested" :get "http://example.com/file.csv" [] []) =
      HTTPTest.get(%{url: "http://example.com/file.csv"})
  end

  test "streaming with a :post term" do
    assert ~s("requested" :post "http://url" [] [term: :post]) =
      HTTPTest.get(%{url: "http://url"}, [{:term, :post}])
  end

  test "streaming with headers" do
    assert ~s("requested" :get "http://url" [{"Authorization", "pass"}] [headers: [{\"Authorization\", \"pass\"}]]) =
      HTTPTest.get(%{url: "http://url"}, [{:headers, [{"Authorization", "pass"}]}])
  end

  test "streaming with body" do
    assert ~s("requested" :get "http://url" [] [body: 123]) =
      HTTPTest.get(%{url: "http://url"}, [{:body, 123}])
  end

  test "when client fails" do
    assert_raise HTTP.Error, "requesting foo, got: {:error, :invalid_url}", fn ->
      HTTPTest.get(%{url: "foo"}, [{:body, 123}])
    end
  end
end
