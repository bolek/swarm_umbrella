module Datasets.List exposing (..)

import Html exposing (..)
import Html.Attributes exposing(..)
import Msgs exposing (Msg)
import Models exposing(Dataset)
import Routing exposing(datasetPath, datasetNewPath)

view : List Dataset -> Html Msg
view datasets =
  div []
  [
    div
      [class "row"]
      [ div
        [class "col"]
        [table
          [ classList
            [ ("table", True)
            , ("table-sm", True)
            , ("table-bordered ", True)
            ]
          ]
          [ headerView
          , tbody
            []
            (List.map datasetView datasets)
          ]
        ]
      ]
    , actionView
    ]

headerView : Html Msg
headerView =
  thead
    []
    [ tr
      []
      [ th [] [text "#"]
      , th [] [text "name "]
      , th [] [text "url"]
      ]
    ]

datasetView : Dataset -> Html Msg
datasetView dataset =
  tr
  []
  [ th
    [attribute "scope" "row"]
    [text(toString dataset.id)]
  , td
    []
    [ a
      [ href (datasetPath dataset.id) ]
      [text dataset.name]
    ]
  , td
    []
    [text dataset.url]
  ]

actionView : Html Msg
actionView =
  div
  [class "row"]
  [ div
    [class "col"]
    [a
      [ class "btn btn-primary"
      , href datasetNewPath
      ] [text "Add"]]

  ]
