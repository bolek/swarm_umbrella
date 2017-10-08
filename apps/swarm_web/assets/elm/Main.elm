module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

type alias Model =
  String

type alias Dataset =
  { name : String
  , url : String
  }

init : ( Model, Cmd Msg)
init =
  ( "Hello", Cmd.none )

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
    , text model
    ]

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
