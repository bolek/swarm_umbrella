module Data.Source
  exposing
    ( Source(..)
    , LocalFileInfo
    , GDriveInfo
    , sourceDecoder
    )

import Json.Decode as JD
import Json.Decode.Pipeline exposing (decode, required, optional)

type Source
  = GDriveSource GDriveInfo
  | LocalFile LocalFileInfo

type alias LocalFileInfo =
  { path : String }

type alias GDriveInfo =
  { file_id : Int }

-- SERIALIZATION --

gDriveSourceDecoder : JD.Decoder Source
gDriveSourceDecoder =
  JD.map GDriveSource gDriveInfoDecoder

gDriveInfoDecoder : JD.Decoder GDriveInfo
gDriveInfoDecoder =
  decode GDriveInfo
    |> required "file_id" JD.int

localFileSourceDecoder : JD.Decoder Source
localFileSourceDecoder =
  JD.map LocalFile localFileInfoDecoder

localFileInfoDecoder : JD.Decoder LocalFileInfo
localFileInfoDecoder =
  decode LocalFileInfo
    |> required "path" JD.string

sourceDecoder : JD.Decoder Source
sourceDecoder =
  JD.field "type" JD.string
    |> JD.andThen sourceHelp

sourceHelp : String -> JD.Decoder Source
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
