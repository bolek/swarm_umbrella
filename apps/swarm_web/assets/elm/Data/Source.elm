module Data.Source
  exposing
    ( Source(..)
    , LocalFileInfo
    , GDriveInfo
    )

type Source
  = GDriveSource GDriveInfo
  | LocalFile LocalFileInfo

type alias LocalFileInfo =
  { path : String }

type alias GDriveInfo =
  { file_id : Int }
