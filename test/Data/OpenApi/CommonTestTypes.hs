{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Data.OpenApi.CommonTestTypes where

import           Prelude               ()
import           Prelude.Compat

import           Data.Aeson            (ToJSON (..), ToJSONKey (..), Value)
import           Data.Aeson.QQ.Simple
import           Data.Aeson.Types      (toJSONKeyText)
import           Data.Char
import           Data.Map              (Map)
import           Data.Proxy
import           Data.Set              (Set)
import qualified Data.Text             as Text
import           Data.Word
import           GHC.Generics

import           Data.OpenApi

-- ========================================================================
-- Unit type
-- ========================================================================

data Unit = Unit deriving (Generic)
instance ToParamSchema Unit
instance ToSchema Unit

unitSchemaJSON :: Value
unitSchemaJSON = [aesonQQ|
{
  "type": "string",
  "enum": ["Unit"]
}
|]

-- ========================================================================
-- Color (enum)
-- ========================================================================
data Color
  = Red
  | Green
  | Blue
  deriving (Generic)
instance ToParamSchema Color
instance ToSchema Color

colorSchemaJSON :: Value
colorSchemaJSON = [aesonQQ|
{
  "type": "string",
  "enum": ["Red", "Green", "Blue"]
}
|]

-- ========================================================================
-- Shade (paramSchemaToNamedSchema)
-- ========================================================================

data Shade = Dim | Bright deriving (Generic)
instance ToParamSchema Shade

instance ToSchema Shade where declareNamedSchema = pure . paramSchemaToNamedSchema defaultSchemaOptions

shadeSchemaJSON :: Value
shadeSchemaJSON = [aesonQQ|
{
  "type": "string",
  "enum": ["Dim", "Bright"]
}
|]

-- ========================================================================
-- Paint (record with bounded enum property)
-- ========================================================================

newtype Paint = Paint { color :: Color }
  deriving (Generic)
instance ToSchema Paint

paintSchemaJSON :: Value
paintSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "color":
        {
          "$ref": "#/components/schemas/Color"
        }
    },
  "required": ["color"]
}
|]

paintInlinedSchemaJSON :: Value
paintInlinedSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "color":
        {
          "type": "string",
          "enum": ["Red", "Green", "Blue"]
        }
    },
  "required": ["color"]
}
|]

-- ========================================================================
-- Status (constructorTagModifier)
-- ========================================================================

data Status
  = StatusOk
  | StatusError
  deriving (Generic)

instance ToParamSchema Status where
  toParamSchema = genericToParamSchema defaultSchemaOptions
    { constructorTagModifier = map toLower . drop (length "Status") }
instance ToSchema Status where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { constructorTagModifier = map toLower . drop (length "Status") }

statusSchemaJSON :: Value
statusSchemaJSON = [aesonQQ|
{
  "type": "string",
  "enum": ["ok", "error"]
}
|]

-- ========================================================================
-- Email (newtype with unwrapUnaryRecords set to True)
-- ========================================================================

newtype Email = Email { getEmail :: String }
  deriving (Generic)
instance ToParamSchema Email
instance ToSchema Email where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { unwrapUnaryRecords = True }

emailSchemaJSON :: Value
emailSchemaJSON = [aesonQQ|
{
  "type": "string"
}
|]

-- ========================================================================
-- UserId (non-record newtype)
-- ========================================================================

newtype UserId = UserId Integer
  deriving (Eq, Ord, Generic)
instance ToParamSchema UserId
instance ToSchema UserId

userIdSchemaJSON :: Value
userIdSchemaJSON = [aesonQQ|
{
  "type": "integer"
}
|]

-- ========================================================================
-- UserGroup (set newtype)
-- ========================================================================

newtype UserGroup = UserGroup (Set UserId)
  deriving (Generic)
instance ToSchema UserGroup

userGroupSchemaJSON :: Value
userGroupSchemaJSON = [aesonQQ|
{
  "type": "array",
  "items": { "$ref": "#/components/schemas/UserId" },
  "uniqueItems": true
}
|]

-- ========================================================================
-- Person (simple record with optional fields)
-- ========================================================================
data Person = Person
  { name  :: String
  , phone :: Integer
  , email :: Maybe String
  } deriving (Generic)

instance ToSchema Person

personSchemaJSON :: Value
personSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "name":   { "type": "string"  },
      "phone":  { "type": "integer" },
      "email":  { "type": "string"  }
    },
  "required": ["name", "phone"]
}
|]

-- ========================================================================
-- Player (record newtype)
-- ========================================================================

newtype Player = Player
  { position :: Point
  } deriving (Generic)
instance ToSchema Player

playerSchemaJSON :: Value
playerSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "position":
        {
          "$ref": "#/components/schemas/Point"
        }
    },
  "required": ["position"]
}
|]

newtype Players = Players [Inlined Player]
  deriving (Generic)
instance ToSchema Players

playersSchemaJSON :: Value
playersSchemaJSON = [aesonQQ|
{
  "type": "array",
  "items":
    {
      "type": "object",
      "properties":
        {
          "position":
            {
              "$ref": "#/components/schemas/Point"
            }
        },
      "required": ["position"]
    }
}
|]

-- ========================================================================
-- Character (sum type with ref and record in alternative)
-- ========================================================================

data Character
  = PC Player
  | NPC { npcName :: String, npcPosition :: Point }
  deriving (Generic)
instance ToSchema Character

characterSchemaJSON :: Value
characterSchemaJSON = [aesonQQ|
{
  "oneOf": [
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "PC"
          ]
        },
        "contents": {
          "$ref": "#/components/schemas/Player"
        }
      }
    },
    {
      "required": [
        "npcName",
        "npcPosition",
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "NPC"
          ]
        },
        "npcPosition": {
          "$ref": "#/components/schemas/Point"
        },
        "npcName": {
          "type": "string"
        }
      }
    }
  ],
  "type": "object"
}

|]

characterInlinedSchemaJSON :: Value
characterInlinedSchemaJSON = [aesonQQ|
{
  "oneOf": [
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "PC"
          ]
        },
        "contents": {
          "required": [
            "position"
          ],
          "type": "object",
          "properties": {
            "position": {
              "required": [
                "x",
                "y"
              ],
              "type": "object",
              "properties": {
                "x": {
                  "format": "double",
                  "type": "number"
                },
                "y": {
                  "format": "double",
                  "type": "number"
                }
              }
            }
          }
        }
      }
    },
    {
      "required": [
        "npcName",
        "npcPosition",
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "NPC"
          ]
        },
        "npcPosition": {
          "required": [
            "x",
            "y"
          ],
          "type": "object",
          "properties": {
            "x": {
              "format": "double",
              "type": "number"
            },
            "y": {
              "format": "double",
              "type": "number"
            }
          }
        },
        "npcName": {
          "type": "string"
        }
      }
    }
  ],
  "type": "object"
}
|]

characterInlinedPlayerSchemaJSON :: Value
characterInlinedPlayerSchemaJSON = [aesonQQ|
{
  "oneOf": [
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "PC"
          ]
        },
        "contents": {
          "required": [
            "position"
          ],
          "type": "object",
          "properties": {
            "position": {
              "$ref": "#/components/schemas/Point"
            }
          }
        }
      }
    },
    {
      "required": [
        "npcName",
        "npcPosition",
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "NPC"
          ]
        },
        "npcPosition": {
          "$ref": "#/components/schemas/Point"
        },
        "npcName": {
          "type": "string"
        }
      }
    }
  ],
  "type": "object"
}
|]

-- ========================================================================
-- ISPair (non-record product data type)
-- ========================================================================
data ISPair = ISPair Integer String
  deriving (Generic)

instance ToSchema ISPair

ispairSchemaJSON :: Value
ispairSchemaJSON = [aesonQQ|
{
  "type": "array",
  "items":
    [
      { "type": "integer" },
      { "type": "string"  }
    ],
  "minItems": 2,
  "maxItems": 2
}
|]

-- ========================================================================
-- Point (record data type with custom fieldLabelModifier)
-- ========================================================================

data Point = Point
  { pointX :: Double
  , pointY :: Double
  } deriving (Generic)

instance ToSchema Point where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { fieldLabelModifier = map toLower . drop (length "point") }

pointSchemaJSON :: Value
pointSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "x": { "type": "number", "format": "double" },
      "y": { "type": "number", "format": "double" }
    },
  "required": ["x", "y"]
}
|]

-- ========================================================================
-- Point (record data type with multiple fields)
-- ========================================================================

data Point5 = Point5
  { point5X :: Double
  , point5Y :: Double
  , point5Z :: Double
  , point5U :: Double
  , point5V :: Double -- 5 dimensional!
  } deriving (Generic)

instance ToSchema Point5 where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { fieldLabelModifier = map toLower . drop (length "point5") }

point5SchemaJSON :: Value
point5SchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "x": { "type": "number", "format": "double" },
      "y": { "type": "number", "format": "double" },
      "z": { "type": "number", "format": "double" },
      "u": { "type": "number", "format": "double" },
      "v": { "type": "number", "format": "double" }
    },
  "required": ["x", "y", "z", "u", "v"]
}
|]

point5Properties :: [String]
point5Properties = ["x", "y", "z", "u", "v"]

-- ========================================================================
-- MyRoseTree (custom datatypeNameModifier)
-- ========================================================================

data MyRoseTree = MyRoseTree
  { root  :: String
  , trees :: [MyRoseTree]
  } deriving (Generic)

instance ToSchema MyRoseTree where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { datatypeNameModifier = drop (length "My") }

myRoseTreeSchemaJSON :: Value
myRoseTreeSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "root": { "type": "string" },
      "trees":
        {
          "type": "array",
          "items":
            {
              "$ref": "#/components/schemas/RoseTree"
            }
        }
    },
  "required": ["root", "trees"]
}
|]

data MyRoseTree' = MyRoseTree'
  { root'  :: String
  , trees' :: [MyRoseTree']
  } deriving (Generic)

instance ToSchema MyRoseTree' where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { datatypeNameModifier = map toLower }

myRoseTreeSchemaJSON' :: Value
myRoseTreeSchemaJSON' = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "root'": { "type": "string" },
      "trees'":
        {
          "type": "array",
          "items":
            {
              "$ref": "#/components/schemas/myrosetree'"
            }
        }
    },
  "required": ["root'", "trees'"]
}
|]

-- ========================================================================
-- Inlined (newtype for inlining schemas)
-- ========================================================================

newtype Inlined a = Inlined { getInlined :: a }

instance ToSchema a => ToSchema (Inlined a) where
  declareNamedSchema _ = unname <$> declareNamedSchema (Proxy :: Proxy a)
    where
      unname (NamedSchema _ s) = NamedSchema Nothing s

-- ========================================================================
-- Light (sum type with unwrapUnaryRecords)
-- ========================================================================

data Light
  = NoLight
  | LightFreq Double
  | LightColor Color
  | LightWaveLength { waveLength :: Double }
  deriving (Generic)

instance ToSchema Light where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { unwrapUnaryRecords = True }

lightSchemaJSON :: Value
lightSchemaJSON = [aesonQQ|
{
  "oneOf": [
    {
      "required": [
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "NoLight"
          ]
        }
      }
    },
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "LightFreq"
          ]
        },
        "contents": {
          "format": "double",
          "type": "number"
        }
      }
    },
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "LightColor"
          ]
        },
        "contents": {
          "$ref": "#/components/schemas/Color"
        }
      }
    },
    {
      "required": [
        "waveLength",
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "LightWaveLength"
          ]
        },
        "waveLength": {
          "format": "double",
          "type": "number"
        }
      }
    }
  ],
  "type": "object"
}
|]

lightInlinedSchemaJSON :: Value
lightInlinedSchemaJSON = [aesonQQ|
{
  "oneOf": [
    {
      "required": [
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "NoLight"
          ]
        }
      }
    },
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "LightFreq"
          ]
        },
        "contents": {
          "format": "double",
          "type": "number"
        }
      }
    },
    {
      "required": [
        "tag",
        "contents"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "LightColor"
          ]
        },
        "contents": {
          "type": "string",
          "enum": [
            "Red",
            "Green",
            "Blue"
          ]
        }
      }
    },
    {
      "required": [
        "waveLength",
        "tag"
      ],
      "type": "object",
      "properties": {
        "tag": {
          "type": "string",
          "enum": [
            "LightWaveLength"
          ]
        },
        "waveLength": {
          "format": "double",
          "type": "number"
        }
      }
    }
  ],
  "type": "object"
}
|]

-- ========================================================================
-- ResourceId (series of newtypes)
-- ========================================================================

newtype Id = Id String deriving (Generic)
instance ToSchema Id

newtype ResourceId = ResourceId Id deriving (Generic)
instance ToSchema ResourceId

-- ========================================================================
-- ButtonImages (bounded enum key mapping)
-- ========================================================================

data ButtonState = Neutral | Focus | Active | Hover | Disabled
  deriving (Show, Bounded, Enum, Generic)

instance ToJSON ButtonState
instance ToSchema ButtonState
instance ToJSONKey ButtonState where toJSONKey = toJSONKeyText (Text.pack . show)

type ImageUrl = Text.Text

newtype ButtonImages = ButtonImages { getButtonImages :: Map ButtonState ImageUrl }
  deriving (Generic)

instance ToJSON ButtonImages where
  toJSON = toJSON . getButtonImages

instance ToSchema ButtonImages where
  declareNamedSchema = genericDeclareNamedSchemaNewtype defaultSchemaOptions
    declareSchemaBoundedEnumKeyMapping

buttonImagesSchemaJSON :: Value
buttonImagesSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "Neutral":  { "type": "string" },
      "Focus":    { "type": "string" },
      "Active":   { "type": "string" },
      "Hover":    { "type": "string" },
      "Disabled": { "type": "string" }
    }
}
|]

-- ========================================================================
-- SingleMaybeField (single field data with optional field)
-- ========================================================================

data SingleMaybeField = SingleMaybeField { singleMaybeField :: Maybe String }
  deriving (Show, Generic)

instance ToJSON SingleMaybeField
instance ToSchema SingleMaybeField

singleMaybeFieldSchemaJSON :: Value
singleMaybeFieldSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "singleMaybeField": { "type": "string" }
    }
}
|]

-- ========================================================================
-- Natural Language (single field data with recursive fields)
-- ========================================================================

data Predicate
  = PredicateNoun    Noun
  | PredicateOmitted Omitted
  deriving (Eq, Ord, Read, Show, Generic)
instance ToJSON Predicate
instance ToSchema Predicate

data Noun
  = Noun
  { nounSurf   :: LangWord
  , nounModify :: [Modifier]
  }
  deriving (Eq, Ord, Read, Show, Generic)
instance ToJSON Noun
instance ToSchema Noun

data LangWord
  = LangWord
  { langWordSurf :: String
  , langWordBase :: String
  }
  deriving (Eq, Ord, Read, Show, Generic)
instance ToJSON LangWord
instance ToSchema LangWord

data Modifier
  = ModifierNoun     Noun
  | ModifierOmitted  Omitted
  deriving (Eq, Ord, Read, Show, Generic)
instance ToJSON Modifier
instance ToSchema Modifier

newtype Omitted
  = Omitted
  { omittedModify :: [Modifier]
  }
  deriving (Eq, Ord, Read, Show, Generic)
instance ToJSON Omitted
instance ToSchema Omitted

predicateSchemaDeclareJSON :: Value
predicateSchemaDeclareJSON = [aesonQQ|
[
  {
    "Predicate": {
      "oneOf": [
        {
          "properties": {
            "contents": { "$ref": "#/components/schemas/Noun" },
            "tag": { "enum": ["PredicateNoun"], "type": "string" }
          },
          "required": ["tag", "contents"],
          "type": "object"
        },
        {
          "properties": {
            "contents": { "$ref": "#/components/schemas/Omitted" },
            "tag": { "enum": ["PredicateOmitted"], "type": "string" }
          },
          "required": ["tag", "contents"],
          "type": "object"
        }
      ],
      "type": "object"
    },
    "Noun": {
      "properties": {
        "nounModify": {
          "items": { "$ref": "#/components/schemas/Modifier" },
          "type": "array"
        },
        "nounSurf": { "$ref": "#/components/schemas/LangWord" }
      },
      "required": ["nounSurf", "nounModify"],
      "type": "object"
    },
    "LangWord": {
      "properties": {
        "langWordBase": { "type": "string" },
        "langWordSurf": { "type": "string" }
      },
      "required": ["langWordSurf", "langWordBase"],
      "type": "object"
    },
    "Modifier": {
      "oneOf": [
        {
          "properties": {
            "contents": { "$ref": "#/components/schemas/Noun" },
            "tag": { "enum": ["ModifierNoun"], "type": "string" }
          },
          "required": ["tag", "contents"],
          "type": "object"
        },
        {
          "properties": {
            "contents": { "$ref": "#/components/schemas/Omitted" },
            "tag": { "enum": ["ModifierOmitted"], "type": "string" }
          },
          "required": ["tag", "contents"],
          "type": "object"
        }
      ],
      "type": "object"
    },
    "Omitted": {
      "properties": {
        "omittedModify": {
          "items": { "$ref": "#/components/schemas/Modifier" },
          "type": "array"
        }
      },
      "required": ["omittedModify"],
      "type": "object"
    }
  },
  { "$ref": "#/components/schemas/Predicate" }
]
|]

-- ========================================================================
-- TimeOfDay
-- ========================================================================
data TimeOfDay
  = Int
  | Pico
  deriving (Generic)
instance ToSchema TimeOfDay
instance ToParamSchema TimeOfDay


timeOfDaySchemaJSON :: Value
timeOfDaySchemaJSON = [aesonQQ|
{
  "example": "12:33:15",
  "type": "string",
  "format": "hh:MM:ss"
}
|]

timeOfDayParamSchemaJSON :: Value
timeOfDayParamSchemaJSON = [aesonQQ|
{
  "type": "string",
  "format": "hh:MM:ss"
}
|]


-- ========================================================================
-- UnsignedInts
-- ========================================================================
data UnsignedInts = UnsignedInts
  { unsignedIntsUint32 :: Word32
  , unsignedIntsUint64 :: Word64
  } deriving (Generic)

instance ToSchema UnsignedInts where
  declareNamedSchema = genericDeclareNamedSchema defaultSchemaOptions
    { fieldLabelModifier = map toLower . drop (length "unsignedInts") }

unsignedIntsSchemaJSON :: Value
unsignedIntsSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "uint32": { "type": "integer", "format": "int32", "minimum": 0, "maximum": 4294967295 },
      "uint64": { "type": "integer", "format": "int64", "minimum": 0, "maximum": 18446744073709551615 }
    },
  "required": ["uint32", "uint64"]
}
|]
