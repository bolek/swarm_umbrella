module Datasets.Show exposing (..)
import Html exposing (..)
import Html.Attributes exposing(class, href, placeholder, type_, for, value)
import Msgs exposing (Msg)
import Models exposing(Dataset, DatasetId, Model)
import Routing exposing(datasetsPath)

view : Dataset -> Html Msg
view model =
  div []
    [ a [ href datasetsPath ] [text "<- Datasets"]
    , h1 [] [text "Show Dataset"]
    , form []
      [ div [class "form-group row"]
        [ label [for "datasetName", class "col-sm-2 col-form-label"] [text "Name"]
        , div [class "col-sm-10"] [
          input [type_ "text", placeholder "Funky Dataset", class "form-control", value model.name] []
          ]
        ]
      , div [class "form-group row"]
        [ label [for "datasetUrl", class "col-sm-2 col-form-label"] [text "URL"]
        , div [class "col-sm-10"] [
          input [type_ "text", placeholder "www.funky.url", class "form-control", value model.url] []
          ]
        ]
      ]
    ]
