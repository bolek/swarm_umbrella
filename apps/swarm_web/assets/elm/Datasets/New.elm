module Datasets.New exposing (view)

import Html exposing (..)
import Html.Attributes exposing(href)
import Msgs exposing (Msg)
import Routing exposing(datasetsPath)

view : Html Msg
view =
  div []
    [ a [ href datasetsPath ] [text "<- Datasets"]
    , h1 [] [text "New Dataset"]
    ]
