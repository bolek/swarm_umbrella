defmodule SwarmEngine.Endpoints.StringIOTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Endpoints.StringIO
  alias SwarmEngine.{Consumer, Resource}

  def request(source) do
    source
    |> Consumer.stream()
    |> Enum.to_list()
    |> Enum.join(" ")
  end

  test "creating a StringIO source" do
    assert StringIO.create("source name", "some random string") ==
             %StringIO{content: "some random string", name: "source name"}
  end

  test "changeset is valid when provided with valid attributes" do
    attrs = %{name: "dataset1", content: "foobar"}

    changeset = StringIO.changeset(%StringIO{}, attrs)

    assert changeset.valid?
  end

  test "streaming a StringIO" do
    source = StringIO.create("name", "some text")
    all_elements = Enum.to_list(Consumer.stream(source))

    assert [
             %SwarmEngine.Message{
               body: "some text",
               headers: %{
                 resource: %SwarmEngine.Resource{
                   modified_at: nil,
                   name: "name",
                   size: 9,
                   source: %SwarmEngine.Endpoints.StringIO{
                     content: "some text",
                     name: "name",
                     type: "StringIO"
                   }
                 },
                 size: 9
               }
             }
           ] = all_elements
  end

  test "metadata happy path" do
    source = StringIO.create("content", "some text")

    expected = {:ok, %Resource{name: "content", size: 9, source: source, modified_at: nil}}

    assert expected == Consumer.metadata(source)
  end
end
