# Example for VersionedJson Module

You can run this example in `elm-reactor`:

```
cd .../elm-versioned-json/examples
elm reactor
```

Then aim your browser at [localhost:8000](http://localhost:8000).

You'll see the following output:

```
json0:	{"foo":0}
json1:	{"version":1,"value":"{\"foo\":1,\"bar\":\"model1.bar\"}"}
json1Err: {"version":1,"value":"{\"foo\":0}"}
json2:	{"version":2,"value":"{\"foo\":2,\"bar\":\"model2.bar\",\"bletch\":[0,1,2]}"}
json2Err: {"version":2,"value":"{\"foo\":1,\"bar\":\"model1.bar\"}"}
m1j0:	{ foo = 0, bar = "" }
m1j1:	{ foo = 1, bar = "model1.bar" }
m1j1Err: Error: Expecting an object with a field named `bar` but instead got: {"foo":0}
m2j0:	{ foo = 0, bar = "", bletch = [] }
m2j1:	{ foo = 1, bar = "model1.bar", bletch = [] }
m2j2:	{ foo = 2, bar = "model2.bar", bletch = [0,1,2] }
m2j2Err: Error: Expecting an object with a field named `bletch` but instead got: {"foo":1,"bar":"model1.bar"}
```
The two functions in the `VersionedJson` module, `encodeVersionedJson` and `decodeVersionedJson` are meant to be usable at the beginning of a project, or at some time after you have already built JSON encoders and decoders for your state.

[Main.elm](Main.elm) contains three different models, `Model0`, `Model1`, and `Model2`, which are designed to represent a possible extension of an application model over time.

`encodeN` encodes a `ModelN` instance into a `String`, in the natural way for record types:

```
type alias Model0 =
  { foo : Int
  }

encoder0 : Model0 -> JE.Value
encoder0 model =
  JE.object [("foo", JE.int model.foo)]

encode0 : Model0 -> String
encode0 model =
  JE.encode 0 <| encoder0 model

type alias Model1 =
  { foo : Int
  , bar : String
  }

encoder1 : Model1 -> JE.Value
encoder1 model =
  JE.object [ ("foo", JE.int model.foo)
            , ("bar", JE.string model.bar)
            ]

encode1 : Model1 -> String
encode1 model =
  JE.encode 0 <| encoder1 model

type alias Model2 =
  { foo : Int
  , bar : String
  , bletch : List Int
  }

encoder2 : Model2 -> JE.Value
encoder2 model =
  JE.object [ ("foo", JE.int model.foo)
            , ("bar", JE.string model.bar)
            , ("bletch", JE.list (List.map JE.int model.bletch))
            ]

encode2 : Model2 -> String
encode2 model =
  JE.encode 0 <| encoder2 model
```

Each `modelN` is a record of type `ModelN`:

```
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
  , bletch = [0, 1, 2]
  }
```

Each `jsonN` is a string for the JSON representation of `modelN`:

```
json0 : String
json0 =
  encode0 model0

json1 : String
json1 =
  encodeVersionedJson 1 model1 encode1

json2 : String
json2 =
  encodeVersionedJson 2 model2 encode2
```

To illustrate the error handling, there are two erroneously-encoded JSON strings:

```
json1Err : String
json1Err =
  encodeVersionedJson 1 model0 encode0

json2Err : String
json2Err =
  encodeVersionedJson 2 model1 encode1
```

The decoders are where it gets interesting, and where your code will benefit from using `encodeVersionedJson` to encode your JSON and `decodeVersionedJson` to decode it.

First I created decoders to pull out each single record property:

```
propDecoder : String -> Decoder x -> Decoder x
propDecoder prop decoder =
  (prop := decoder)

fooDecoder : Decoder Int
fooDecoder = propDecoder "foo" JD.int

barDecoder : Decoder String
barDecoder = propDecoder "bar" JD.string

bletchDecoder : Decoder (List Int)
bletchDecoder = propDecoder "bletch" (JD.list JD.int)
```

Then decoding functions for each of the models, each built on the decoder for the earlier model:

```
decode0 : String -> Result String Model0
decode0 json =
  case JD.decodeString fooDecoder json of
    Err s -> Err s
    Ok foo ->
      Ok { foo = foo }

decode1 : String -> Result String Model1
decode1 json =
  case decode0 json of
    Err s -> Err s
    Ok model0 ->
      case JD.decodeString barDecoder json of
        Err s2 -> Err s2
        Ok bar ->
          Ok { foo = model0.foo
             , bar = bar }

decode2 : String -> Result String Model2
decode2 json =
  case decode1 json of
    Err s -> Err s
    Ok model1 ->
      case JD.decodeString bletchDecoder json of
        Err s2 -> Err s2
        Ok bletch ->
          Ok { foo = model1.foo
             , bar = model1.bar
             , bletch = bletch }
```

Sometimes your model will change such that you can't build a decoder on the previous version. You'll have to deal with that. Or, better, try to only grow your models in ways that make it possible.

Every time you move to a new model, you need to build a converter from each previous model to the new one. So to move from `Model0` to `Model1`:

```
model0To1 : Model0 -> Model1
model0To1 model =
  { foo = model.foo
  , bar = ""
  }
```

And to move from `Model1` to `Model2`:

```
model1To2 : Model1 -> Model2
model1To2 model =
  { foo = model.foo
  , bar = model.bar
  , bletch = []
  }
```

You have to provide a default value for the new state missing in the old model.

Finally, we can make converters that take old JSON representations and turn them into new models. For the `Model0` to `Model1` conversion, that is:

```
model0StringToModel1 : String -> Result String Model1
model0StringToModel1 json =
  case decode0 json of
    Err s -> Err s
    Ok model0 ->
      Ok (model0To1 model0)
```

For the `Model1` to `Model2` conversion:

```
model0StringToModel2 : String -> Result String Model2
model0StringToModel2 json =
  case model0StringToModel1 json of
    Err s -> Err s
    Ok model1 ->
      Ok (model1To2 model1)

model1StringToModel2 : String -> Result String Model2
model1StringToModel2 json =
  case decode1 json of
    Err s -> Err s
    Ok model1 ->
      Ok (model1To2 model1)
```

For `ModelN` you need to write N upgrade functions, but they can largely be built from earlier upgrade functions that you've written before.

Finally, we can create the conversion dictionaries, for passing to `decodeVersionedJson`. This one converts JSON for `Model0` or `Model1` to `Model1`:

```
converter1Dict : ConverterDict Model1
converter1Dict =
  Dict.fromList
    [ (0, model0StringToModel1)
    , (1, decode1)
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
```

And this one converts the JSON for `Model0`, `Model1`, or `Model2` to `Model2`:

```
converter2Dict : ConverterDict Model2
converter2Dict =
  Dict.fromList
    [ (0, model0StringToModel2)
    , (1, model1StringToModel2)
    , (2, decode2)
    ]

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
```

To sort things differently, when you upgrade from `Model0` to `Model1`, you need to write the following:

```
type alias Model1 =
  { foo : Int
  , bar : String
  }

encoder1 : Model1 -> JE.Value
encoder1 model =
  JE.object [ ("foo", JE.int model.foo)
            , ("bar", JE.string model.bar)
            ]

encode1 : Model1 -> String
encode1 model =
  JE.encode 0 <| encoder1 model

decode1 : String -> Result String Model1
decode1 json =
  case decode0 json of
    Err s -> Err s
    Ok model0 ->
      case JD.decodeString barDecoder json of
        Err s2 -> Err s2
        Ok bar ->
          Ok { foo = model0.foo
             , bar = bar }

model0To1 : Model0 -> Model1
model0To1 model =
  { foo = model.foo
  , bar = ""
  }

model0StringToModel1 : String -> Result String Model1
model0StringToModel1 json =
  case decode0 json of
    Err s -> Err s
    Ok model0 ->
      Ok (model0To1 model0)

converter1Dict : ConverterDict Model1
converter1Dict =
  Dict.fromList
    [ (0, model0StringToModel1)
    , (1, decode1)
    ]
```

And you'll convert to and from JSON with the following:

```
encodeVersionedJson 1 model encode1

decodeVersionedJson json converter1Dict
```

And when you upgrade from `Model1` to `Model2`, you need to write these:

```
type alias Model2 =
  { foo : Int
  , bar : String
  , bletch : List Int
  }

encoder2 : Model2 -> JE.Value
encoder2 model =
  JE.object [ ("foo", JE.int model.foo)
            , ("bar", JE.string model.bar)
            , ("bletch", JE.list (List.map JE.int model.bletch))
            ]

encode2 : Model2 -> String
encode2 model =
  JE.encode 0 <| encoder2 model

decode2 : String -> Result String Model2
decode2 json =
  case decode1 json of
    Err s -> Err s
    Ok model1 ->
      case JD.decodeString bletchDecoder json of
        Err s2 -> Err s2
        Ok bletch ->
          Ok { foo = model1.foo
             , bar = model1.bar
             , bletch = bletch }

model1To2 : Model1 -> Model2
model1To2 model =
  { foo = model.foo
  , bar = model.bar
  , bletch = []
  }

model0StringToModel2 : String -> Result String Model2
model0StringToModel2 json =
  case model0StringToModel1 json of
    Err s -> Err s
    Ok model1 ->
      Ok (model1To2 model1)

model1StringToModel2 : String -> Result String Model2
model1StringToModel2 json =
  case decode1 json of
    Err s -> Err s
    Ok model1 ->
      Ok (model1To2 model1)

converter2Dict : ConverterDict Model2
converter2Dict =
  Dict.fromList
    [ (0, model0StringToModel2)
    , (1, model1StringToModel2)
    , (2, decode2)
    ]
```

And you need only a small change to your JSON conversion code, changing 1 to 2 in three places:

```
encodeVersionedJson 2 model encode2

decodeVersionedJson json converter2Dict
```

Happy hacking!

Bill St. Clair &lt;[billstclair@gmail.com](mailto:billstclair@gmail.com)&gt;<br/>
14 November 2016
