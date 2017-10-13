module Models exposing (..)

type alias Model =
  { datasets: List Dataset
  , route : Route }

initialModel : Route -> Model
initialModel route =
    { datasets =
      [ {id = 1, name = "Sample.csv", url = "www.example.com/sample.csv"}
      , {id = 2, name = "Sample.csv", url = "www.example.com/sample.csv"}
      ]
    , route = route }

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
