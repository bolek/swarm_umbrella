module Main exposing(..)

import Data.Dataset as Dataset exposing (Dataset)
import Data.Decoder
import Data.Source

import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE
import Json.Decode.Pipeline exposing (decode, required, optional)

import Html exposing(..)
import Html.Attributes exposing(class, classList, href, for, type_, value)
import Html.Events exposing (onClick, onInput)

-- Navigation
import Navigation
import UrlParser exposing (..)

--import Json.Encode as JE
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import Phoenix.Push as Push
--import Phoenix.Presence as Presence exposing (Presence)

import ConnectionStatus exposing(ConnectionStatus)

main : Program Flags Model Msg
main =
  Navigation.programWithFlags UrlChange
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
  , currentLocation : Navigation.Location
  , currentRoute : Route
  }

-- Routing ---------------------------------------------------------------------

type Route
  = DatasetsRoute
  | NewDatasetRoute
  | NotFoundRoute

matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ UrlParser.map DatasetsRoute UrlParser.top
        , UrlParser.map NewDatasetRoute (UrlParser.s "datasets" </> UrlParser.s "new")
        , UrlParser.map DatasetsRoute (UrlParser.s "datasets")
        ]

parseLocation : Navigation.Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute

datasetsPath : String
datasetsPath =
  "#/datasets"

newDatasetPath : String
newDatasetPath =
  "#/datasets/new"

-- End of routing --------------------------------------------------------------

initModel : Navigation.Location -> Flags -> Model
initModel location flags =
  { connectionStatus = ConnectionStatus.Disconnected
  , flags = flags
  , datasetCreatorModel = initDatasetCreator
  , datasets = []
  , currentLocation = location
  , currentRoute = parseLocation location
  }

init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
  (initModel location flags, Cmd.none)

dataset : String -> Result String Dataset
dataset jsonString =
  JD.decodeString Dataset.decoder jsonString

datasetsDecoder : Decoder Datasets
datasetsDecoder =
  decode
    Datasets
    |> required "data" (JD.list Dataset.decoder)

datasets : String -> Result String Datasets
datasets jsonString =
  JD.decodeString datasetsDecoder jsonString

encodeNewDataset : NewDataset -> JE.Value
encodeNewDataset dataset =
  JE.object
    [ ("name", JE.string dataset.name)
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
  | TrackDataset NewDataset
  | UrlChange Navigation.Location

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
      { model | datasetCreatorModel = initDatasetCreator } ! [(trackDataset model dataset)]
    UrlChange location ->
      { model | currentLocation = location, currentRoute = parseLocation location } ! []

fetchDatasets : Model -> Cmd Msg
fetchDatasets model =
  let
    push =
      Push.init "datasets" "fetch"
  in
    Phoenix.push (socketUrl model) push

trackDataset : Model -> NewDataset -> Cmd Msg
trackDataset model dataset =
  let
    push =
      Push.init "datasets" "track"
        |> Push.withPayload (JE.object [ ( "msg", encodeNewDataset dataset ) ])
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
  case model.currentRoute of
    DatasetsRoute ->
      Html.div []
      [ Html.h1 [] [ text "Datasets"]
      , Html.a [href newDatasetPath] [text "new dataset"]
      , (viewDatasetsList model.datasets)
      ]
    NewDatasetRoute ->
      Html.div []
      [ Html.h1 [] [text "New Dataset"]
      , datasetCreatorView model.datasetCreatorModel
      ]
    NotFoundRoute ->
      Html.div []
      [ Html.h1 [] [text "Not Found"]
      ]

viewDataset : Dataset -> Html Msg
viewDataset dataset =
  Html.div [class "dataset"]
    [ Html.div [class "dataset_name"] [text dataset.name]
    , Html.div [class "dataset_tracker"]
      [ Html.label [] [text "tracker: "]
      , text (case dataset.tracker.source of
          Data.Source.LocalFile f -> "LocalFile (" ++ f.path ++ ")"
          Data.Source.GDriveSource g -> "GoogleDrive"
        )
      ]
    , Html.div [class "dataset_decoder"]
      [ Html.label [] [text "decoder: "]
      , text (case dataset.decoder of
          Data.Decoder.CSV f -> "CSV (delimiter: \"" ++ f.delimiter ++ "\", separator: \""++ f.separator ++"\", headers: "++ (if f.headers then "yes" else "no") ++")"
        )
      ]
    ]

viewDatasetItem : Dataset -> Html Msg
viewDatasetItem dataset =
  Html.li [] [(viewDataset dataset)]

viewDatasetsList : List Dataset -> Html Msg
viewDatasetsList datasets =
  Html.ul [] (List.map viewDatasetItem datasets)

type alias SourceOption
  = { id : Int, source : Data.Source.Source, name : String, selected : Bool }

type alias SourceOptions
  = List SourceOption

type alias DecoderOption
  = { id : Int, decoder : Data.Decoder.Decoder, name : String, selected : Bool}

type alias DecoderOptions
  = List DecoderOption


type alias NewDataset =
  { name : String
  , source : Maybe Data.Source.Source
  , decoder : Maybe Data.Decoder.Decoder
  }

type alias DatasetCreatorModel
  = { decoderOptions : DecoderOptions
    , newDataset : NewDataset
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
    , newDataset = NewDataset "" Nothing Nothing
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
    , Html.div [class "actions"]
      [ Html.button [type_ "submit", onClick <| createDataset model] [text "track"]
      , Html.a [href datasetsPath] [text "cancel"]
      ]
    ]
