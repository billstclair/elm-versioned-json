module VersionedJson exposing (ConverterDict, encodeVersionedJson, decodeVersionedJson)

{-| A couple of functions to ease versioning of your JSON representations.

See the README for the [examples](https://github.com/billstclair/elm-versioned-json/tree/master/examples) directory for details.

# Classes
@docs ConverterDict

# Functions
@docs encodeVersionedJson, decodeVersionedJson
-}

import Dict exposing (Dict)
import Json.Decode as JD exposing ((:=))
import Json.Encode as JE

{-| Convert a value to a versioned Json string -}
encodeVersionedJson : Int -> x -> (x -> String) -> String
encodeVersionedJson version value encoder =
  let plist = [ ("version", JE.int version)
              , ("value", JE.string <| encoder value)
              ]
  in
    JE.encode 0 <| JE.object plist

{-| An Elm Dict mapping version numbers to decoder functions -}
type alias ConverterDict x =
  Dict Int (String -> Result String x)

versionAndValue : JD.Decoder (Int, String)
versionAndValue =
  JD.object2 (,)
    ("version" := JD.int)
    ("value" := JD.string)

{-| Decode a string saved by `encodeVersionedJson` with the relavant converter function
from a dictionary you provide.

If the string is not as encoded by `encodeVersionedJson`, use the converter function
for version 0.
-}
decodeVersionedJson : String -> ConverterDict x -> Result String x
decodeVersionedJson json dict =
  case JD.decodeString versionAndValue json of
    Err _ ->
      case Dict.get 0 dict of
        Nothing -> Err "No converter for version 0."
        Just c -> c json
    Ok (version, value) ->
      case Dict.get version dict of
        Nothing -> Err ("No converter for version " ++ toString(version))
        Just c -> c value
