module Data.Decoder
  exposing
    ( CSVParams
    , Decoder(..)
    , decoder
    )

import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required, optional)

type Decoder
  = CSV CSVParams

type alias CSVParams
  = { delimiter : String
    , headers : Bool
    , separator : String }

-- SERIALIZATION --

decoder : JD.Decoder Decoder
decoder =
  JD.field "type" JD.string
    |> JD.andThen decoderHelp

decoderHelp : String -> JD.Decoder Decoder
decoderHelp type_ =
  case type_ of
    "Elixir.SwarmEngine.Decoders.CSV" ->
      csvDecoder
    _ ->
      JD.fail <|
        "Trying to decode decoder, but type "
        ++ type_ ++ " is not supported"

csvDecoder : JD.Decoder Decoder
csvDecoder
  = JD.field "args" (JD.map CSV csvParamsDecoder)

csvParamsDecoder : JD.Decoder CSVParams
csvParamsDecoder
  = decode CSVParams
    |> required "delimiter" JD.string
    |> required "headers" JD.bool
    |> required "separator" JD.string

