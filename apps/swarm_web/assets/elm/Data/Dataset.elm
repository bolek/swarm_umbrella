module Data.Dataset
  exposing
    ( Dataset
    , decoder )

import Data.Decoder as Decoder exposing (Decoder)
import Data.Tracker as Tracker exposing (Tracker)
import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required, optional)

type alias Dataset =
  { name : String
  , decoder : Decoder
  , tracker : Tracker
  }

-- SERIALIZATION --

decoder : JD.Decoder Dataset
decoder =
  decode Dataset
    |> required "name" JD.string
    |> required "decoder" Decoder.decoder
    |> required "tracker" Tracker.decoder
