module Datasets.Show exposing (..)
import Html exposing (..)
import Html.Attributes exposing(href)
import Msgs exposing (Msg)
import Models exposing(Dataset, DatasetId, Model)
import Routing exposing(datasetsPath)

view : Model -> Html Msg
view model =
  div []
    [ a [ href datasetsPath ] [text "<- Datasets"]
    , h1 [] [text "Show Dataset"]
    ]
