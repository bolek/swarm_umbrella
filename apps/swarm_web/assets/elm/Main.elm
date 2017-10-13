module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing(..)
import Datasets.List
import Datasets.Show
import Datasets.New
import Models exposing (initialModel, Model, Dataset)
import Msgs exposing (Msg)
import Update exposing(update)
import Navigation exposing(program, Location)
import Routing exposing (..)

init : Location -> ( Model, Cmd Msg )
init location =
  let
    currentRoute =
      Routing.parseLocation location
  in
    (initialModel currentRoute, Cmd.none)


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
        Datasets.Show.view model

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

main : Program Never Model Msg
main =
  Navigation.program Msgs.OnLocationChange
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
