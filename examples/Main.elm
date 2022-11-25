module Main exposing (..)

import Browser
import Dict
import Html
    exposing
        ( Attribute
        , Html
        , table
        , td
        , text
        , tr
        )
import Html.Attributes exposing (style)
import Json.Decode as JD exposing (Decoder, field)
import Json.Encode as JE
import VersionedJson exposing (ConverterDict, decodeVersionedJson, encodeVersionedJson)


main =
    Browser.element
        { init = \() -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model0 =
    { foo : Int
    }


encoder0 : Model0 -> JE.Value
encoder0 model =
    JE.object [ ( "foo", JE.int model.foo ) ]


encode0 : Model0 -> String
encode0 model =
    JE.encode 0 <| encoder0 model


propDecoder : String -> Decoder x -> Decoder x
propDecoder prop decoder =
    field prop decoder


fooDecoder : Decoder Int
fooDecoder =
    propDecoder "foo" JD.int


barDecoder : Decoder String
barDecoder =
    propDecoder "bar" JD.string


bletchDecoder : Decoder (List Int)
bletchDecoder =
    propDecoder "bletch" (JD.list JD.int)


decode0 : String -> Result String Model0
decode0 json =
    case JD.decodeString fooDecoder json of
        Err s ->
            Err <| JD.errorToString s

        Ok foo ->
            Ok { foo = foo }


type alias Model1 =
    { foo : Int
    , bar : String
    }


encoder1 : Model1 -> JE.Value
encoder1 model =
    JE.object
        [ ( "foo", JE.int model.foo )
        , ( "bar", JE.string model.bar )
        ]


encode1 : Model1 -> String
encode1 model =
    JE.encode 0 <| encoder1 model


decode1 : String -> Result String Model1
decode1 json =
    case decode0 json of
        Err s ->
            Err s

        Ok mdl ->
            case JD.decodeString barDecoder json of
                Err s2 ->
                    Err <| JD.errorToString s2

                Ok bar ->
                    Ok
                        { foo = mdl.foo
                        , bar = bar
                        }


type alias Model2 =
    { foo : Int
    , bar : String
    , bletch : List Int
    }


encoder2 : Model2 -> JE.Value
encoder2 model =
    JE.object
        [ ( "foo", JE.int model.foo )
        , ( "bar", JE.string model.bar )
        , ( "bletch", JE.list JE.int model.bletch )
        ]


encode2 : Model2 -> String
encode2 model =
    JE.encode 0 <| encoder2 model


decode2 : String -> Result String Model2
decode2 json =
    case decode1 json of
        Err s ->
            Err s

        Ok mdl ->
            case JD.decodeString bletchDecoder json of
                Err s2 ->
                    Err <| JD.errorToString s2

                Ok bletch ->
                    Ok
                        { foo = mdl.foo
                        , bar = mdl.bar
                        , bletch = bletch
                        }


model0 : Model0
model0 =
    { foo = 0 }


model1 : Model1
model1 =
    { foo = 1
    , bar = "model1.bar"
    }


model2 : Model2
model2 =
    { foo = 2
    , bar = "model2.bar"
    , bletch = [ 0, 1, 2 ]
    }


type alias Model =
    Model2


init : ( Model, Cmd Msg )
init =
    ( model2
    , Cmd.none
    )


model0To1 : Model0 -> Model1
model0To1 model =
    { foo = model.foo
    , bar = ""
    }


model1To2 : Model1 -> Model2
model1To2 model =
    { foo = model.foo
    , bar = model.bar
    , bletch = []
    }


model0StringToModel1 : String -> Result String Model1
model0StringToModel1 json =
    case decode0 json of
        Err s ->
            Err s

        Ok mdl ->
            Ok (model0To1 mdl)


model0StringToModel2 : String -> Result String Model2
model0StringToModel2 json =
    case model0StringToModel1 json of
        Err s ->
            Err s

        Ok mdl ->
            Ok (model1To2 mdl)


model1StringToModel2 : String -> Result String Model2
model1StringToModel2 json =
    case decode1 json of
        Err s ->
            Err s

        Ok mdl ->
            Ok (model1To2 mdl)


json0 : String
json0 =
    encode0 model0


json1 : String
json1 =
    encodeVersionedJson 1 model1 encode1


json1Err : String
json1Err =
    encodeVersionedJson 1 model0 encode0


json2 : String
json2 =
    encodeVersionedJson 2 model2 encode2


json2Err : String
json2Err =
    encodeVersionedJson 2 model1 encode1


converter1Dict : ConverterDict Model1
converter1Dict =
    Dict.fromList
        [ ( 0, model0StringToModel1 )
        , ( 1, decode1 )
        ]


converter2Dict : ConverterDict Model2
converter2Dict =
    Dict.fromList
        [ ( 0, model0StringToModel2 )
        , ( 1, model1StringToModel2 )
        , ( 2, decode2 )
        ]


m1j0 : Result String Model1
m1j0 =
    decodeVersionedJson json0 converter1Dict


m1j1 : Result String Model1
m1j1 =
    decodeVersionedJson json1 converter1Dict


m1j1Err : Result String Model1
m1j1Err =
    decodeVersionedJson json1Err converter1Dict


m2j0 : Result String Model2
m2j0 =
    decodeVersionedJson json0 converter2Dict


m2j1 : Result String Model2
m2j1 =
    decodeVersionedJson json1 converter2Dict


m2j2 : Result String Model2
m2j2 =
    decodeVersionedJson json2 converter2Dict


m2j2Err : Result String Model2
m2j2Err =
    decodeVersionedJson json2Err converter2Dict


tos : Result String x -> String
tos res =
    case res of
        Err s ->
            "Error: " ++ s

        Ok x ->
            Debug.toString x


mjStrings =
    { m1j0 = tos m1j0
    , m1j1 = tos m1j1
    , m1j1Err = tos m1j1Err
    , m2j0 = tos m2j0
    , m2j1 = tos m2j1
    , m2j2 = tos m2j2
    , m2j2Err = tos m2j2Err
    }


type Msg
    = Nop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Nop ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    table []
        [ tr [] [ td [] [ text "json0:" ], td [] [ text json0 ] ]
        , tr [] [ td [] [ text "json1:" ], td [] [ text json1 ] ]
        , tr [] [ td [] [ text "json1Err:" ], td [] [ text json1Err ] ]
        , tr [] [ td [] [ text "json2:" ], td [] [ text json2 ] ]
        , tr [] [ td [] [ text "json2Err:" ], td [] [ text json2Err ] ]
        , tr [] [ td [] [ text "m1j0:" ], td [] [ text mjStrings.m1j0 ] ]
        , tr [] [ td [] [ text "m1j1:" ], td [] [ text mjStrings.m1j1 ] ]
        , tr [] [ td [] [ text "m1j1Err:" ], td [] [ text mjStrings.m1j1Err ] ]
        , tr [] [ td [] [ text "m2j0:" ], td [] [ text mjStrings.m2j0 ] ]
        , tr [] [ td [] [ text "m2j1:" ], td [] [ text mjStrings.m2j1 ] ]
        , tr [] [ td [] [ text "m2j2:" ], td [] [ text mjStrings.m2j2 ] ]
        , tr [] [ td [] [ text "m2j2Err:" ], td [] [ text mjStrings.m2j2Err ] ]
        ]
