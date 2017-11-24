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
  , datasetCreatorModel : DatasetCreatorModel
  , datasets : List Dataset
  }

initModel : Flags -> Model
initModel flags =
  { connectionStatus = ConnectionStatus.Disconnected
  , flags = flags
  , datasetCreatorModel = initDatasetCreator
  , datasets = []
  }

initDataset : Dataset
initDataset = Dataset "" "" Nothing

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
  | NewDatasetState DatasetCreatorModel
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
    NewDatasetState datasetCreatorModel ->
      { model | datasetCreatorModel = datasetCreatorModel } ! []
    TrackDataset dataset ->
      let
        newDatasets = model.datasets ++ [dataset]
      in
        { model | datasetCreatorModel = initDatasetCreator
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

view : Model -> Html Msg
view model =
  Html.div []
    [ Html.p []
      [ text (connectionStatusDescription model.connectionStatus) ]
    , Html.h1 [] [text "Datasets"]
    , datasetCreatorView model.datasetCreatorModel
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

-- Create Dataset Wizard

type alias SourceOption
  = { id : Int, source : Source, name : String, selected : Bool }

type alias SourceOptions
  = List SourceOption

type alias DatasetCreatorModel
  = {newDataset : Dataset, sourceOptions : SourceOptions}

initSourceOptions : SourceOptions
initSourceOptions =
  [ SourceOption 1 (LocalFile {path = ""}) "Local File" False
  , SourceOption 2 (GDriveSource 1) "Google Drive" False
  ]

initDatasetCreator : DatasetCreatorModel
initDatasetCreator = {newDataset = initDataset, sourceOptions = initSourceOptions}

sourceOption : DatasetCreatorModel -> SourceOption -> Html Msg
sourceOption model option =
  Html.div
    [ class "source-btn",
      classList [("active", option.selected)]
    , onClick <| (selectSourceOption model option)
    ]
    [ text option.name
    ]

selectSourceOption : DatasetCreatorModel -> SourceOption -> Msg
selectSourceOption ({newDataset, sourceOptions} as model) option =
  NewDatasetState {model
    | newDataset = { newDataset | source = Just option.source}
    , sourceOptions = (List.map (\x -> if option.id == x.id then {x | selected = not option.selected} else x) initSourceOptions)
    }

setTitle : DatasetCreatorModel -> String -> Msg
setTitle ({newDataset} as model) value =
  NewDatasetState {model | newDataset = {newDataset | title = value}}

setUrl : DatasetCreatorModel -> String -> Msg
setUrl ({newDataset} as model) value =
  NewDatasetState {model | newDataset = {newDataset | url = value}}

createDataset : DatasetCreatorModel -> Msg
createDataset model =
  TrackDataset model.newDataset

datasetCreatorView : DatasetCreatorModel -> Html Msg
datasetCreatorView model =
  Html.form [class "form"]
    [
      Html.div [class "container-fluid create-dataset"]
      [ Html.div [class "row"] [Html.h2 [] [text "Create new dataset"]]
      , Html.div [class "row"] [Html.h3 [] [text "Select source:"]]
      , Html.div [class "row d-flex flex-wrap"]
        (List.map (\option ->
          Html.div [class "p-2"] [sourceOption model option]
        ) model.sourceOptions)
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
        , onInput <| setTitle model] []
      ]
    , Html.div [class "form-group"]
      [ Html.label [class "mr-sm-2"] [text "URL"]
      , Html.input
        [ type_ "text"
        , for "url"
        , class "form-control mb-2 mr-sm-2 mb-sm-0"
        , value model.newDataset.url
        , onInput <| setUrl model] []
      ]
    , Html.button [type_ "button", class "btn btn-primary", onClick <| createDataset model] [text "Track"]
    ]
