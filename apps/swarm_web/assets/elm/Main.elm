module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing(..)
import Datasets.List
import Datasets.Show
import Datasets.New
import Models exposing (initialModel, Flags, Model, Dataset)
import Msgs exposing (Msg)
import Update exposing(update)
import Navigation exposing(program, Location)
import Routing exposing (..)

init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
  let
    currentRoute =
      Routing.parseLocation location
  in
    (initialModel flags currentRoute, Cmd.none)


-- VIEW

view : Model -> Html Msg
view model =
  div
  [ class "container" ]
  [ headerView
  , hr [] []
  , case model.route of
      Models.DatasetsRoute ->
        Datasets.List.view model.datasets

      Models.DatasetRoute id ->
        let
          maybeDataset =
            model.datasets
              |> List.filter (\dataset -> dataset.id == id)
              |> List.head
        in
          case maybeDataset of
            Just dataset ->
              Datasets.Show.view dataset

            Nothing ->
                notFoundView

      Models.DatasetNewRoute ->
        Datasets.New.view

      Models.NotFoundRoute ->
        notFoundView
  ]

notFoundView : Html Msg
notFoundView =
  h1
  []
  [text "Not FOUND"]

headerView : Html Msg
headerView =
  h1
  []
  [text "Swarm"]

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- MAIN

main : Program Flags Model Msg
main =
  Navigation.programWithFlags Msgs.OnLocationChange
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
