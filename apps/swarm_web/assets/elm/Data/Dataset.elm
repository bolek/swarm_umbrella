module Data.Dataset
  exposing
    ( Dataset
    , decoder )

import Data.Decoder as Decoder exposing (Decoder)
import Data.Source as Source exposing (Source)
import Data.Tracker as Tracker exposing (Tracker)
import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required, optional)

type alias Dataset =
  { name : String
  , url : String
  , source : Maybe Source
  , decoder : Maybe Decoder
  , tracker : Maybe Tracker
  }

-- SERIALIZATION --

decoder : JD.Decoder Dataset
decoder =
  decode Dataset
    |> required "name" JD.string
    |> required "url" (JD.map (Maybe.withDefault "") (JD.nullable JD.string))
    |> optional "source" (Source.decoder |> JD.maybe) Nothing
    |> optional "decoder" (Decoder.decoder |> JD.maybe) Nothing
    |> optional "tracker" (Tracker.decoder |> JD.maybe) Nothing
