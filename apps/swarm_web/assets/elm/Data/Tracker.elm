module Data.Tracker
  exposing
    ( Tracker
    , decoder
    )

import Data.Source as Source exposing(Source)
import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required)

type alias Tracker
  = { source : Source }

-- SERIALIZATION --

decoder : JD.Decoder Tracker
decoder =
  decode Tracker
    |> required "source" Source.decoder
