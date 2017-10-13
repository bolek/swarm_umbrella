module Routing exposing (..)

import Navigation exposing (Location)
import Models exposing (DatasetId, Route(..))
import UrlParser exposing (..)

matchers : Parser (Route -> a) a
matchers =
  oneOf
    [ map DatasetsRoute top
    , map DatasetNewRoute (s "datasets" </> s "new")
    , map DatasetRoute (s "datasets" </> int)
    , map DatasetsRoute (s "datasets")
    ]

parseLocation : Location -> Route
parseLocation location =
  case (parseHash matchers location) of
    Just route ->
      route

    Nothing ->
      NotFoundRoute

datasetNewPath : String
datasetNewPath =
  "#datasets/new"

datasetsPath : String
datasetsPath =
  "#datasets"

datasetPath : DatasetId -> String
datasetPath id =
  "#datasets/" ++ toString(id)
