{-# LANGUAGE OverloadedStrings #-}
module Generator.Util
  ( CodeGenException(..)
  , get
  , toTitle
  , unTitle
  , toCamelName
  , withDir
  , unLines
  , descContent
  )
where

import           RIO
import qualified RIO.Char                      as C
import qualified RIO.Directory                 as Dir
import qualified RIO.List                      as L
import qualified RIO.Text                      as T
import           Generator.Types                ( CodeGenException(..) )

get :: MonadThrow m => (t -> Maybe b) -> Text -> t -> m b
get f s desc = maybe (throwM $ GetException s) pure (f desc)

toTitle :: Text -> Text
toTitle = applyHead C.toUpper

unTitle :: Text -> Text
unTitle = applyHead C.toLower

applyHead :: (Char -> Char) -> Text -> Text
applyHead f text = maybe text (\(c, t) -> T.cons (f c) t) (T.uncons text)

toCamelName :: Text -> Text
toCamelName = toTitle . T.concat . fmap toTitle . T.split (not . C.isAlphaNum)

withDir :: FilePath -> IO a -> IO a
withDir dir action = do
  Dir.createDirectoryIfMissing True dir
  Dir.withCurrentDirectory dir action

unLines :: [Text] -> Text
unLines = T.intercalate "\n\n" . filter (not . T.null)

descContent :: Int -> Maybe Text -> Text
descContent n = maybe
  ""
  (\s ->
    indent
      <> "{-|\n"
      <> (T.unlines . fmap ((indent <> "  ") <>) . T.lines $ s)
      <> indent
      <> "-}\n"
  )
  where indent = T.concat $ take n $ L.repeat " "
