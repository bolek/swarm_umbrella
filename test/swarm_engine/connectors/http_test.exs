defmodule SwarmEngine.Connectors.HTTPTest do
  use ExUnit.Case, async: true

  alias __MODULE__

  doctest SwarmEngine.Dataset

  def get(params) do
    SwarmEngine.Connectors.HTTP.get(params)
      |> Enum.to_list()
      |> Enum.join(" ")
  end

  def get(params, options) do
    SwarmEngine.Connectors.HTTP.get(params, options)
      |> Enum.to_list()
      |> Enum.join(" ")
  end

  test "streaming a file" do
    assert ~s("requested" :get "http://example.com/file.csv" [] []) =
      HTTPTest.get(%{url: "http://example.com/file.csv"})
  end

  test "streaming with a :post term" do
    assert ~s("requested" :post "url" [] [term: :post]) =
      HTTPTest.get(%{url: "url"}, [{:term, :post}])
  end

  test "streaming with headers" do
    assert ~s("requested" :get "url" [{"Authorization", "pass"}] [headers: [{\"Authorization\", \"pass\"}]]) =
      HTTPTest.get(%{url: "url"}, [{:headers, [{"Authorization", "pass"}]}])
  end

  test "streaming with body" do
    assert ~s("requested" :get "url" [] [body: 123]) =
      HTTPTest.get(%{url: "url"}, [{:body, 123}])
  end
end
