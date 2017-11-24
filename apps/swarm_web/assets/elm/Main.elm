module Main exposing(..)

import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE
import Json.Decode.Pipeline exposing (decode, required, optional)

import Html exposing(..)
import Html.Attributes exposing(class, classList, for, type_, value)
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

type Source
  = GDriveSource Int
  | LocalFile LocalFileInfo

type alias SourceBtn
  = { id : Int, source : Source, name : String, selected : Bool }

type alias SourceBtns
  = List SourceBtn

type alias LocalFileInfo =
  { path : String }

type alias Dataset =
  { title : String, url : String, source : Maybe Source }

type alias Datasets =
  { datasets : List Dataset }

type alias Flags =
  { socketUrl : String }

type alias Model =
  { flags : Flags
  , connectionStatus : ConnectionStatus
  , newDataset : Dataset
  , datasets : List Dataset
  , sourceBtns : SourceBtns}

initModel : Flags -> Model
initModel flags =
  { connectionStatus = ConnectionStatus.Disconnected
  , flags = flags
  , newDataset = initDataset
  , datasets = []
  , sourceBtns = initSourceBtns }

initDataset : Dataset
initDataset = Dataset "" "" Nothing

initSourceBtns : SourceBtns
initSourceBtns =
  [ SourceBtn 1 (LocalFile {path = ""}) "Local File" False
  , SourceBtn 2 (GDriveSource 1) "Google Drive" False]

init : Flags -> ( Model, Cmd Msg )
init flags =
  (initModel flags, Cmd.none)

-- decoders

gDriveSourceDecoder : Decoder Source
gDriveSourceDecoder =
  decode GDriveSource
    |> required "file_id" JD.int

localFileSourceDecoder : Decoder Source
localFileSourceDecoder =
  JD.map LocalFile localFileInfoDecoder

localFileInfoDecoder : Decoder LocalFileInfo
localFileInfoDecoder =
  decode LocalFileInfo
    |> required "path" JD.string

sourceDecoder : Decoder Source
sourceDecoder =
  JD.field "type" JD.string
    |> JD.andThen sourceHelp

sourceHelp : String -> Decoder Source
sourceHelp type_ =
  case type_ of
    "LocalFile" ->
      localFileSourceDecoder
    "GDrive" ->
      gDriveSourceDecoder
    _ ->
      JD.fail <|
        "Trying to decode source, but type "
        ++ type_ ++ " is not supported"

datasetDecoder : Decoder Dataset
datasetDecoder =
  decode Dataset
    |> required "title" JD.string
    |> required "url" (JD.map (Maybe.withDefault "") (JD.nullable JD.string))
    |> optional "source" (sourceDecoder |> JD.maybe) Nothing

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
  | NewDatasetState Dataset SourceBtns
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
    NewDatasetState dataset sourceBtns ->
      { model | newDataset = dataset, sourceBtns = sourceBtns } ! []
    TrackDataset dataset ->
      let
        newDatasets = model.datasets ++ [dataset]
      in
        { model | newDataset = initDataset
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
channel : Channel.Channel Msg
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

setTitle : Dataset -> SourceBtns -> String -> Msg
setTitle dataset sourceBtns value =
  NewDatasetState {dataset | title = value} sourceBtns

setUrl : Dataset -> SourceBtns -> String -> Msg
setUrl dataset sourceBtns value =
  NewDatasetState {dataset | url = value} sourceBtns

onTrackDataset : Dataset -> Msg
onTrackDataset dataset =
  TrackDataset dataset


sourceBtn : SourceBtn -> Dataset -> Html Msg
sourceBtn sbtn dataset =
  Html.div
    [ class "source-btn",
      classList [("active", sbtn.selected)]
    , onClick (
      NewDatasetState {dataset | source = (Just sbtn.source)}
        (List.map (\x -> if sbtn.id == x.id then {x | selected = not sbtn.selected} else x) initSourceBtns)
      )
    ]
    [ text sbtn.name
    ]

view : Model -> Html Msg
view model =
  Html.div []
    [ Html.p []
      [ text (connectionStatusDescription model.connectionStatus) ]
    , Html.h1 [] [text "Datasets"]
-- Create New Dataset
    , Html.form [class "form"]
      [
        Html.div [class "container-fluid create-dataset"]
        [ Html.div [class "row"] [Html.h2 [] [text "Create new dataset"]]
        , Html.div [class "row"] [Html.h3 [] [text "Select source:"]]
        , Html.div [class "row d-flex flex-wrap"]
          (List.map (\x ->
            Html.div [class "p-2"] [sourceBtn x model.newDataset]
          ) model.sourceBtns)
        , case model.newDataset.source of
            Just (LocalFile s) -> Html.div [class "row"] [text "Source"]
            Just (GDriveSource _) -> Html.text ""
            Nothing -> Html.text ""
        ]
      , Html.div [class "form-group"]
        [ Html.label [class "mr-sm-2"] [text "Title"]
        , Html.input
          [ type_ "text"
          , for "title"
          , class "form-control mb-2 mr-sm-2 mb-sm-0"
          , value model.newDataset.title
          , onInput <| setTitle model.newDataset model.sourceBtns] []
        ]
      , Html.div [class "form-group"]
        [ Html.label [class "mr-sm-2"] [text "URL"]
        , Html.input
          [ type_ "text"
          , for "url"
          , class "form-control mb-2 mr-sm-2 mb-sm-0"
          , value model.newDataset.url
          , onInput <| setUrl model.newDataset model.sourceBtns] []
        ]
      , Html.button [type_ "button", class "btn btn-primary", onClick <| onTrackDataset model.newDataset] [text "Track"]
      ]

    , Html.hr [] []
    , Html.h2 [] [text "Tracked"]
    , Html.ul []
      (List.map (\dataset ->
        Html.li []
          [text (String.join " " [dataset.title, dataset.url,
            case dataset.source of
              Just (LocalFile l) -> "LocalFile, path: " ++ l.path
              Just (GDriveSource _) -> "Google Drive"
              Nothing -> "boom"
          ])]
        ) model.datasets
      )
    ]
