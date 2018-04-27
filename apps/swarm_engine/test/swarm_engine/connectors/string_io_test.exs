defmodule SwarmEngine.Connectors.StringIOTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Connectors.StringIO
  alias SwarmEngine.{Connector, Resource}

  def request(source) do
    source
    |> Connector.request()
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
    all_elements = Enum.to_list(Connector.request(source))

    assert [%SwarmEngine.Message{body: "some text", headers: %{endpoint: ^source}}] = all_elements
  end

  test "metadata happy path" do
    source = StringIO.create("content", "some text")

    expected = {:ok, %Resource{name: "content", size: 9, source: source, modified_at: nil}}

    assert expected == Connector.metadata(source)
  end
end
