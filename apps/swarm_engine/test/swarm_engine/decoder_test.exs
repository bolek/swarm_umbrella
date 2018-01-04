defmodule SwarmEngine.Decoders.DecoderTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Decoder
  alias SwarmEngine.Decoders.CSV

  @decoder %Decoder{
    type: CSV,
    decoder: %CSV{headers: true, separator: ",", delimiter: "\n"}
  }

  @decoder_map %{
    args: %{headers: true, separator: ",", delimiter: "\n"},
    type: SwarmEngine.Decoders.CSV
  }

  test "transforming a Decoder struct to a map" do
    assert SwarmEngine.Mapable.to_map(@decoder) == @decoder_map
  end

  test "creating a decoder from a map" do
    assert Decoder.from_map(@decoder_map) == @decoder
  end

  test "serializing a decoder map" do
    assert Poison.decode!(Poison.encode!(@decoder_map))
      ==  %{"args" => %{"delimiter" => "\n", "headers" => true, "separator" => ","},
            "type" => "Elixir.SwarmEngine.Decoders.CSV"
          }
  end

  test "decoding a serialized decoder map" do
    assert (
      @decoder_map
      |> Poison.encode!()
      |> Poison.decode!(keys: :atoms!)
      |> Decoder.from_map()
    ) == @decoder
  end
end
