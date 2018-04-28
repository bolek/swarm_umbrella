defmodule SwarmEngine.Decoders.CSVTest do
  use ExUnit.Case, async: true

  alias SwarmEngine.Decoders.CSV

  @csvDecoder %CSV{headers: true, separator: ",", delimiter: "\n"}

  test "encoding a CSV decoder to json" do
    assert Poison.decode!(Poison.encode!(@csvDecoder)) ==
             %{
               "type" => "CSV",
               "delimiter" => "\n",
               "headers" => true,
               "separator" => ","
             }
  end

  test "decoding a CSV decoder from json" do
    assert @csvDecoder
           |> Poison.encode!()
           |> Poison.decode!(as: %CSV{}) == @csvDecoder
  end
end
