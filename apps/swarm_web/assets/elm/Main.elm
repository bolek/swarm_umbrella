module Main exposing(..)

import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE
import Json.Decode.Pipeline exposing (decode, required)

import Html exposing(..)
import Html.Attributes exposing(class, for, type_, value)
import Html.Events exposing (onClick, onInput)

--import Json.Encode as JE
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import Phoenix.Push as Push
--import Phoenix.Presence as Presence exposing (Presence)

import ConnectionStatus exposing(ConnectionStatus)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL

type alias Dataset = { title : String, url : String }

type alias Datasets =
  { datasets : List Dataset }

type alias Flags =
  { socketUrl : String }

type alias Model =
  { flags : Flags
  , connectionStatus : ConnectionStatus
  , newDataset : Dataset
  , datasets : List Dataset }

initModel : Flags -> Model
initModel flags =
  { connectionStatus = ConnectionStatus.Disconnected
  , flags = flags
  , newDataset = Dataset "" ""
  , datasets = [] }

init : Flags -> ( Model, Cmd Msg )
init flags =
  (initModel flags, Cmd.none)

-- decoders

datasetDecoder : Decoder Dataset
datasetDecoder =
  decode Dataset
    |> required "title" JD.string
    |> required "url" (JD.map (Maybe.withDefault "") (JD.nullable JD.string))

dataset : String -> Result String Dataset
dataset jsonString =
  JD.decodeString datasetDecoder jsonString

datasetsDecoder : Decoder Datasets
datasetsDecoder =
  decode
    Datasets
    |> required "datasets" (JD.list datasetDecoder)

datasets : String -> Result String Datasets
datasets jsonString =
  JD.decodeString datasetsDecoder jsonString

encodeDataset : Dataset -> JE.Value
encodeDataset dataset =
  JE.object
    [ ("title", JE.string dataset.title)
    , ("url", JE.string dataset.url)
    ]

-- UPDATE

type Msg
  = Connected
  | Disconnected
  | FetchedDatasets JD.Value
  | NewDatasetState Dataset
  | TrackDataset Dataset

update : Msg -> Model -> (Model, Cmd Msg)
update message model =
  case message of
    Connected ->
      { model | connectionStatus = ConnectionStatus.Connected } ! [(fetchDatasets model)]
    Disconnected ->
      { model | connectionStatus = ConnectionStatus.Disconnected } ! []
    FetchedDatasets payload ->
      case JD.decodeValue datasetsDecoder payload of
        Ok datasets ->
          { model | datasets = datasets.datasets } ! []
        Err err ->
          model ! []
    NewDatasetState dataset ->
      { model | newDataset = dataset } ! []
    TrackDataset dataset ->
      let
        newDatasets = model.datasets ++ [dataset]
      in
        { model | newDataset = Dataset "" ""
                , datasets = newDatasets } ! [(trackDataset model dataset)]


fetchDatasets : Model -> Cmd Msg
fetchDatasets model =
  let
    push =
      Push.init "datasets" "fetch"
  in
    Phoenix.push (socketUrl model) push

trackDataset : Model -> Dataset -> Cmd Msg
trackDataset model dataset =
  let
    push =
      Push.init "datasets" "track"
        |> Push.withPayload (JE.object [ ( "msg", encodeDataset dataset ) ])
  in Phoenix.push (socketUrl model) push

-- Subscriptions
channel =
    Channel.init "datasets"
        |> Channel.on "datasets" (\msg -> FetchedDatasets msg)
        -- register an handler for messages with a "new_msg" event

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.connect (socket model) [channel]

socket : Model -> Socket Msg
socket model =
  Socket.init (socketUrl model)
    |> Socket.onOpen (Connected)
    |> Socket.onClose (\_ -> Disconnected)

socketUrl : Model -> String
socketUrl model =
  model.flags.socketUrl

-- View

connectionStatusDescription : ConnectionStatus -> String
connectionStatusDescription connectionStatus =
  case connectionStatus of
    ConnectionStatus.Connected ->
      "Connected"
    ConnectionStatus.Disconnected ->
      "Disconnected"

setTitle : Dataset -> String -> Msg
setTitle dataset value =
  NewDatasetState {dataset | title = value}

setUrl : Dataset -> String -> Msg
setUrl dataset value =
  NewDatasetState {dataset | url = value}

onTrackDataset : Dataset -> Msg
onTrackDataset dataset =
  TrackDataset dataset

view : Model -> Html Msg
view model =
  Html.div []
    [ Html.p []
      [ text (connectionStatusDescription model.connectionStatus) ]
    , Html.h1 [] [text "Datasets"]
    , Html.form [class "form"]
      [ Html.div [class "form-group"]
        [ Html.label [class "mr-sm-2"] [text "Title"]
        , Html.input
          [ type_ "text"
          , for "title"
          , class "form-control mb-2 mr-sm-2 mb-sm-0"
          , value model.newDataset.title
          , onInput <| setTitle model.newDataset] []
        ]
      , Html.div [class "form-group"]
        [ Html.label [class "mr-sm-2"] [text "URL"]
        , Html.input
          [ type_ "text"
          , for "url"
          , class "form-control mb-2 mr-sm-2 mb-sm-0"
          , value model.newDataset.url
          , onInput <| setUrl model.newDataset] []
        ]
      , Html.button [type_ "button", class "btn btn-primary", onClick <| onTrackDataset model.newDataset] [text "Track"]
      ]
    , Html.hr [] []
    , Html.h2 [] [text "Tracked"]
    , Html.ul []
      (List.map (\dataset ->
        Html.li []
          [text (String.join " " [dataset.title, dataset.url])]
        ) model.datasets
      )
    ]
