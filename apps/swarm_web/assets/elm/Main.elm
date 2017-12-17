module Main exposing(..)

import Data.Dataset as Dataset exposing (Dataset)
import Data.Decoder
import Data.Source

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

dataset : String -> Result String Dataset
dataset jsonString =
  JD.decodeString Dataset.decoder jsonString

datasetsDecoder : Decoder Datasets
datasetsDecoder =
  decode
    Datasets
    |> required "datasets" (JD.list Dataset.decoder)

datasets : String -> Result String Datasets
datasets jsonString =
  JD.decodeString datasetsDecoder jsonString

encodeDataset : Dataset -> JE.Value
encodeDataset dataset =
  JE.object
    [ ("name", JE.string dataset.name)
    , ("url", JE.string dataset.url)
    , ("source", case dataset.source of
        Just (Data.Source.LocalFile l) -> JE.object
                              [ ("type", JE.string "LocalFile")
                              , ("path", JE.string l.path)
                              ]
        Just (Data.Source.GDriveSource d) -> JE.object
                              [ ("type", JE.string "GDrive")
                              , ("file_id", JE.int d.file_id)
                              ]
        Nothing -> JE.null
      )
    , ("decoder", case dataset.decoder of
        Just (Data.Decoder.CSV f) -> JE.object
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
              Just (Data.Source.LocalFile l) -> "LocalFile, path: " ++ l.path
              Just (Data.Source.GDriveSource _) -> "Google Drive"
              Nothing -> ""
          , case dataset.decoder of
              Just (Data.Decoder.CSV f) -> "CSV (delimiter: \"" ++ f.delimiter ++ "\", separator: \""++ f.separator ++"\", headers: "++ (if f.headers then "yes" else "no") ++")"
              Nothing -> ""
          ])]
        ) model.datasets
      )
    ]

-- Create Dataset Wizard

type alias SourceOption
  = { id : Int, source : Data.Source.Source, name : String, selected : Bool }

type alias SourceOptions
  = List SourceOption

type alias DecoderOption
  = { id : Int, decoder : Data.Decoder.Decoder, name : String, selected : Bool}

type alias DecoderOptions
  = List DecoderOption

type alias DatasetCreatorModel
  = { decoderOptions : DecoderOptions
    , newDataset : Dataset
    , sourceOptions : SourceOptions
    }

initDecoderOptions : DecoderOptions
initDecoderOptions =
  [ DecoderOption 1 (Data.Decoder.CSV {separator = ",", delimiter = "\n", headers = True}) "CSV" False
  ]

initSourceOptions : SourceOptions
initSourceOptions =
  [ SourceOption 1 (Data.Source.LocalFile {path = ""}) "Local File" False
  , SourceOption 2 (Data.Source.GDriveSource {file_id = 1}) "Google Drive" False
  ]

initDatasetCreator : DatasetCreatorModel
initDatasetCreator
  = { decoderOptions = initDecoderOptions
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

decoderOption : DatasetCreatorModel -> DecoderOption -> Html Msg
decoderOption model decoder =
  Html.div
    [ class "option",
      classList [("active", decoder.selected)]
    , onClick <| (selectDecoderOption model decoder)
    ]
    [ text decoder.name
    ]

selectSourceOption : DatasetCreatorModel -> SourceOption -> Msg
selectSourceOption ({newDataset, sourceOptions} as model) option =
  NewDatasetState {model
    | newDataset = { newDataset | source = (if not option.selected then (Just option.source) else Nothing)}
    , sourceOptions = (List.map (\x -> if option.id == x.id then {x | selected = not option.selected} else x) initSourceOptions)
    }

selectDecoderOption : DatasetCreatorModel -> DecoderOption -> Msg
selectDecoderOption ({newDataset, decoderOptions} as model) option =
  NewDatasetState {model
    | newDataset = { newDataset | decoder = (if not option.selected then (Just option.decoder) else Nothing)}
    , decoderOptions = (List.map (\x -> if option.id == x.id then {x | selected = not option.selected} else x) initDecoderOptions)
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

setLocalFilePath : DatasetCreatorModel -> Data.Source.LocalFileInfo -> String -> Msg
setLocalFilePath ({newDataset} as model) source value =
  NewDatasetState {model | newDataset = {newDataset | source = (Just (Data.Source.LocalFile { source | path = value}))}}

setCSVFormatSeparator : DatasetCreatorModel -> Data.Decoder.CSVParams -> String -> Msg
setCSVFormatSeparator ({newDataset} as model) decoder value =
  NewDatasetState {model | newDataset = {newDataset | decoder = (Just (Data.Decoder.CSV { decoder | separator = value}))}}

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
        Just (Data.Source.LocalFile s) ->
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
              (List.map (\decoder ->
                decoderOption model decoder
              ) model.decoderOptions)
            , case model.newDataset.decoder of
                Just (Data.Decoder.CSV f) ->
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
        Just (Data.Source.GDriveSource _) -> Html.text ""
        Nothing -> Html.text ""
    , Html.button [type_ "button", class "btn btn-primary", onClick <| createDataset model] [text "Track"]
    ]
