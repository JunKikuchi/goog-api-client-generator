{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module JSON.Schema where

import           RIO
import           Data.Aeson                     ( FromJSON(..)
                                                , (.:?)
                                                , withObject
                                                )

-- https://tools.ietf.org/html/draft-zyp-json-schema-03#section-5.1

data Schema
  = Schema
  { schemaType :: Maybe Text
  , schemaDescription :: Maybe Text
  , schemaFormat :: Maybe Text
  } deriving (Show, Generic)

instance FromJSON Schema where
  parseJSON = withObject "Schema" $ \v -> Schema
    <$> v .:? "type"
    <*> v .:? "description"
    <*> v .:? "format"
