module Models exposing (..)

type alias Flags =
  { socketUrl : String }

type alias Model =
  { datasets: List Dataset
  , route : Route
  , flags: Flags }

initialModel : Flags -> Route -> Model
initialModel flags route =
    { datasets =
      [ {id = 1, name = "Sample.csv", url = "www.example.com/sample.csv"}
      , {id = 2, name = "Sample.csv", url = "www.example.com/sample.csv"}
      ]
    , route = route
    , flags = flags }

type alias DatasetId =
    Int

type alias Dataset =
  { id : Int
  , name : String
  , url : String
  }

type Route
    = DatasetsRoute
    | DatasetNewRoute
    | DatasetRoute DatasetId
    | NotFoundRoute
