module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

type alias Model =
  List Dataset

type alias Dataset =
  { name : String
  , url : String
  }

init : ( Model, Cmd Msg)
init =
  ( [ {id = 1, name = "Sample.csv", url = "www.example.com/sample.csv"}
    , {id = 2, name = "Sample.csv", url = "www.example.com/sample.csv"}
    ]
    , Cmd.none
  )

-- MESSAGES

type Msg
  = NoOp

-- VIEW

view : Model -> Html Msg
view model =
  div
    [ class "container" ]
    [ h1
        []
        [text "Swarm"]
    , hr [] []
    , div
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
          [ thead
              []
              [ tr
                []
                [ th [] [text "#"]
                , th [] [text "name "]
                , th [] [text "url"]
                ]
              ]
          , tbody
            []
            [ tr
              []
              [ th
                [attribute "scope" "row"]
                [text "1"]
              , td
                []
                [text "sample.csv"]
              , td
                []
                [text "example.com/sample.csv"]
              ]
            ]
          ]
        ]
      ]
    , div
      [class "row"]
      [ div
        [class "col"]
        [button
          [ class "btn btn-primary"
          , attribute "type" "button"
          ] [text "Add"]]

      ]
    --, div
    --    []
    --    (List.map datasetView model)
    ]

datasetView : Dataset -> Html Msg
datasetView model =
  div
    []
    [span
      []
      [ text model.name
      , text " - "
      , text model.url
      ]
    ]

--datasetList : Model -> Html Msg
--datasetList model =
--  model
--    |> List.map datasetView


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- MAIN

main : Program Never Model Msg
main =
  program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
