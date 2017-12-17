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

-- Source types
type Source
  = GDriveSource GDriveInfo
  | LocalFile LocalFileInfo

type alias LocalFileInfo =
  { path : String }

type alias GDriveInfo =
  { file_id : Int }

-- Format types
type Format
  = CSVFormat CSVInfo

type alias CSVInfo
  = { separator : String }

type alias Dataset =
  { name : String
  , url : String
  , source : Maybe Source
  , format : Maybe Format }

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
initDataset = Dataset "" "" Nothing Nothing

init : Flags -> ( Model, Cmd Msg )
init flags =
  (initModel flags, Cmd.none)

-- decoders

gDriveSourceDecoder : Decoder Source
gDriveSourceDecoder =
  JD.map GDriveSource gDriveInfoDecoder

gDriveInfoDecoder : Decoder GDriveInfo
gDriveInfoDecoder =
  decode GDriveInfo
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

csvInfoDecoder : Decoder CSVInfo
csvInfoDecoder
  = decode CSVInfo
    |> required "separator" JD.string

csvFormatDecoder : Decoder Format
csvFormatDecoder
  = JD.map CSVFormat csvInfoDecoder

formatDecoder : Decoder Format
formatDecoder
  = JD.field "format_type" JD.string
    |> JD.andThen formatHelp

formatHelp : String -> Decoder Format
formatHelp type_ =
  case type_ of
    "CSV" ->
      csvFormatDecoder
    _ ->
      JD.fail <|
        "Trying to decode format, but type "
        ++ type_ ++ " is not supported"

datasetDecoder : Decoder Dataset
datasetDecoder =
  decode Dataset
    |> required "name" JD.string
    |> required "url" (JD.map (Maybe.withDefault "") (JD.nullable JD.string))
    |> optional "source" (sourceDecoder |> JD.maybe) Nothing
    |> optional "format" (formatDecoder |> JD.maybe) Nothing

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
    [ ("name", JE.string dataset.name)
    , ("url", JE.string dataset.url)
    , ("source", case dataset.source of
        Just (LocalFile l) -> JE.object
                              [ ("type", JE.string "LocalFile")
                              , ("path", JE.string l.path)
                              ]
        Just (GDriveSource d) -> JE.object
                              [ ("type", JE.string "GDrive")
                              , ("file_id", JE.int d.file_id)
                              ]
        Nothing -> JE.null
      )
    , ("format", case dataset.format of
        Just (CSVFormat f) -> JE.object
                              [ ("type", JE.string "CSV")
                              , ("separator", JE.string f.separator)
                              ]
        Nothing -> JE.null
      )
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
    [ Html.h1 [] [text "Datasets"]
    , datasetCreatorView model.datasetCreatorModel
    , Html.hr [] []
    , Html.h2 [] [text "Tracked"]
    , Html.ul []
      (List.map (\dataset ->
        Html.li []
          [text (String.join " " [dataset.name, dataset.url,
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

type alias FormatOption
  = { id : Int, format : Format, name : String, selected : Bool}

type alias FormatOptions
  = List FormatOption

type alias DatasetCreatorModel
  = { formatOptions : FormatOptions
    , newDataset : Dataset
    , sourceOptions : SourceOptions
    }

initFormatOptions : FormatOptions
initFormatOptions =
  [ FormatOption 1 (CSVFormat {separator = ","})"CSV" False
  ]

initSourceOptions : SourceOptions
initSourceOptions =
  [ SourceOption 1 (LocalFile {path = ""}) "Local File" False
  , SourceOption 2 (GDriveSource {file_id = 1}) "Google Drive" False
  ]

initDatasetCreator : DatasetCreatorModel
initDatasetCreator
  = { formatOptions = initFormatOptions
    , newDataset = initDataset
    , sourceOptions = initSourceOptions
    }

sourceOption : DatasetCreatorModel -> SourceOption -> Html Msg
sourceOption model option =
  Html.div
    [ class "option",
      classList [("active", option.selected)]
    , onClick <| (selectSourceOption model option)
    ]
    [ text option.name
    ]

formatOption : DatasetCreatorModel -> FormatOption -> Html Msg
formatOption model format =
  Html.div
    [ class "option",
      classList [("active", format.selected)]
    , onClick <| (selectFormatOption model format)
    ]
    [ text format.name
    ]

selectSourceOption : DatasetCreatorModel -> SourceOption -> Msg
selectSourceOption ({newDataset, sourceOptions} as model) option =
  NewDatasetState {model
    | newDataset = { newDataset | source = (if not option.selected then (Just option.source) else Nothing)}
    , sourceOptions = (List.map (\x -> if option.id == x.id then {x | selected = not option.selected} else x) initSourceOptions)
    }

selectFormatOption : DatasetCreatorModel -> FormatOption -> Msg
selectFormatOption ({newDataset, formatOptions} as model) option =
  NewDatasetState {model
    | newDataset = { newDataset | format = (if not option.selected then (Just option.format) else Nothing)}
    , formatOptions = (List.map (\x -> if option.id == x.id then {x | selected = not option.selected} else x) initFormatOptions)
    }

setName : DatasetCreatorModel -> String -> Msg
setName ({newDataset} as model) value =
  NewDatasetState {model | newDataset = {newDataset | name = value}}

setUrl : DatasetCreatorModel -> String -> Msg
setUrl ({newDataset} as model) value =
  NewDatasetState {model | newDataset = {newDataset | url = value}}

createDataset : DatasetCreatorModel -> Msg
createDataset model =
  TrackDataset model.newDataset

setLocalFilePath : DatasetCreatorModel -> LocalFileInfo -> String -> Msg
setLocalFilePath ({newDataset} as model) source value =
  NewDatasetState {model | newDataset = {newDataset | source = (Just (LocalFile { source | path = value}))}}

setCSVFormatSeparator : DatasetCreatorModel -> CSVInfo -> String -> Msg
setCSVFormatSeparator ({newDataset} as model) format value =
  NewDatasetState {model | newDataset = {newDataset | format = (Just (CSVFormat { format | separator = value}))}}

datasetCreatorView : DatasetCreatorModel -> Html Msg
datasetCreatorView model =
  Html.form [class "dataset-create"]
    [ Html.h2 [] [text "Create new dataset"]
    , Html.div [class "form-group"]
      [ Html.label [] [text "Name"]
      , Html.input
        [ type_ "text"
        , for "name"
        , value model.newDataset.name
        , onInput <| setName model] []
      ]
    , Html.h3 [] [text "Select source:"]
    , Html.div [class "options"]
      (List.map (\option ->
        sourceOption model option
      ) model.sourceOptions)
    , case model.newDataset.source of
        Just (LocalFile s) ->
          Html.div []
            [ Html.h3 [] [text "Configure:"]
            , Html.div [class "form-group"]
              [ Html.label [] [text "Path"]
              , Html.input
                [ type_ "text"
                , for "local_file_path"
                , value s.path
                , onInput <| setLocalFilePath model s
                ] []
              ]
            , Html.h3 [] [text "Data format:"]
            , Html.div [class "options"]
              (List.map (\format ->
                formatOption model format
              ) model.formatOptions)
            , case model.newDataset.format of
                Just (CSVFormat f) ->
                  Html.div []
                  [ Html.h3 [] [text "Parameters:"]
                  , Html.div [class "form-group"]
                    [ Html.label [] [text "separator"]
                    , Html.input
                      [ type_ "text"
                      , for "format_csv_separator"
                      , value f.separator
                      , onInput <| setCSVFormatSeparator model f
                      ] []
                    ]
                  ]
                Nothing -> Html.text ""
            ]
        Just (GDriveSource _) -> Html.text ""
        Nothing -> Html.text ""
    , Html.button [type_ "button", class "btn btn-primary", onClick <| createDataset model] [text "Track"]
    ]
