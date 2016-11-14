import VersionedJson exposing (ConverterDict, encodeVersionedJson, decodeVersionedJson)

import Html exposing ( Html, Attribute
                     , div, h1, h2, text, p
                     )
import Html.App as App

main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model =
  {
  }

init : (Model, Cmd Msg)
init =
  ( {}
  , Cmd.none
  )

type Msg =
  Nop

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Nop -> (model, Cmd.none)

subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.none

view : Model -> Html Msg
view model =
  div []
    [ text "Hello World"
    ]
