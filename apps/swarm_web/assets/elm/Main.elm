module Main exposing(..)

import Html exposing(..)
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL

type alias Flags =
  { socketUrl : String }

type alias Model =
  { flags : Flags
  , connectionStatus : ConnectionStatus }

type ConnectionStatus
  = Connected
  | Disconnected

initModel : Flags -> Model
initModel flags =
  { connectionStatus = Disconnected
  , flags = flags }


init : Flags -> ( Model, Cmd Msg )
init flags =
  (initModel flags, Cmd.none)

-- UPDATE

type Msg
  = ConnectionStatusChanged ConnectionStatus

update : Msg -> Model -> (Model, Cmd Msg)
update message model =
  case message of
    ConnectionStatusChanged connectionStatus ->
      { model | connectionStatus = connectionStatus } ! []

-- Subscriptions
channel : Channel.Channel msg
channel =
    Channel.init "datasets"
        -- register an handler for messages with a "new_msg" event
        --|> Channel.on "new_msg" NewMsg

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.connect (socket model) [channel]

socket : Model -> Socket Msg
socket model =
  Socket.init model.flags.socketUrl
    |> Socket.onOpen (ConnectionStatusChanged Connected)
    |> Socket.onClose (\_ -> ConnectionStatusChanged Disconnected)

-- View

connectionStatusDescription : ConnectionStatus -> String
connectionStatusDescription connectionStatus =
  case connectionStatus of
    Connected ->
      "Connected"
    Disconnected ->
      "Disconnected"

view : Model -> Html Msg
view model =
  Html.div []
    [ Html.p []
      [ text (connectionStatusDescription model.connectionStatus) ]
    ]
