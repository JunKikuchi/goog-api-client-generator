{-# LANGUAGE OverloadedStrings #-}
module CodeGen.Schema.Record where

import           RIO
import qualified RIO.Map                       as Map
import qualified RIO.Text                      as T
import           RIO.Writer                     ( runWriterT
                                                , tell
                                                )
import           Discovery.RestDescription.Schema
import qualified JSON.Schema                   as JSON
import           CodeGen.Types
import           CodeGen.Util

createRecord :: Schema -> GenRecord Text
createRecord schema = case schemaType schema of
  (Just (ObjectType obj)) -> do
    name  <- lift $ get schemaId "schema id" schema
    props <- lift $ get objectProperties "object properties" obj
    field <- createField name props
    pure $ createRecordContent name field (Map.size props)
  _ -> undefined

createField :: RecordName -> ObjectProperties -> GenRecord Text
createField name props = do
  fields <- Map.foldrWithKey cons (pure []) props
  pure $ T.intercalate "\n  , " fields
 where
  cons s schema acc = do
    let camelName = T.concat . fmap toTitle . T.split (== '_') $ s
        fieldName = unTitle name <> toTitle camelName
    field <- createContent fieldName schema
    (field :) <$> acc
  createContent fieldName schema = do
    fieldType <- createType (toTitle fieldName) schema
    pure $ fieldName <> " :: " <> fieldType

createType :: ObjectName -> JSON.Schema -> GenRecord Text
createType name schema = case JSON.schemaType schema of
  (Just (JSON.StringType  _  )) -> pure "Text"
  (Just (JSON.IntegerType _  )) -> pure "Int"
  (Just (JSON.NumberType  _  )) -> pure "Float"
  (Just (JSON.ObjectType  obj)) -> do
    tell [GenObject (name, obj)]
    pure name
  (Just (JSON.ArrayType array)) -> createArrayType name array
  (Just JSON.BooleanType      ) -> pure "Bool"
  (Just (JSON.RefType ref)    ) -> do
    tell [GenRef ref]
    pure ref
  _ -> undefined

createArrayType :: ObjectName -> JSON.Array -> GenRecord Text
createArrayType name array = case JSON.arrayItems array of
  (Just (JSON.ArrayItemsItem schema)) -> do
    fieldType <- createType name schema
    pure $ "[" <> fieldType <> "]"
  _ -> undefined

createRecordContent :: RecordName -> Text -> Int -> Text
createRecordContent name field size =
  (if size == 1 then "newtype " else "data ")
    <> name
    <> " = "
    <> name
    <> (if size == 0 then "" else "\n  { " <> field <> "\n  }")
    <> " deriving Show"

createFieldRecords :: [Gen] -> GenRef Text
createFieldRecords = fmap (T.intercalate "\n\n") . foldr f (pure [])
 where
  f :: Gen -> GenRef [Text] -> GenRef [Text]
  f (GenRef ref) acc = do
    tell [ref]
    acc
  f (GenObject obj) acc = do
    (a, objs) <- lift $ runWriterT $ createFieldRecord obj
    if null objs
      then (a :) <$> acc
      else do
        b <- createFieldRecords objs
        (a :) <$> ((b :) <$> acc)

createFieldRecord :: CodeGen.Types.Object -> GenRecord Text
createFieldRecord obj = do
  fields <- createFieldRecordFields obj
  field  <- createFieldRecordField obj
  maybe (error "faild to get JSON object properties nor additionalProperties")
        pure
        (fields <|> field)

createFieldRecordFields :: CodeGen.Types.Object -> GenRecord (Maybe Text)
createFieldRecordFields (name, obj) = case JSON.objectProperties obj of
  (Just props) -> do
    field <- createField name props
    pure . pure $ createRecordContent name field (Map.size props)
  Nothing -> pure Nothing

createFieldRecordField :: CodeGen.Types.Object -> GenRecord (Maybe Text)
createFieldRecordField (name, obj) =
  case JSON.objectAdditionalProperties obj of
    (Just (JSON.AdditionalPropertiesSchema schema)) -> do
      fieldType <- createType name schema
      let field = T.concat ["un", name] <> " :: Map Text " <> fieldType
      pure . pure $ createRecordContent name field 1
    (Just (JSON.AdditionalPropertiesBool _)) -> undefined
    Nothing -> pure Nothing
