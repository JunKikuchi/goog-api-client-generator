module Generator.Types where

import           RIO
import           RIO.Writer                     ( WriterT )

newtype CodeGenException = GetException Text deriving Show
instance Exception CodeGenException

type DistDir     = FilePath
type ProjectDir  = FilePath
type SrcDir      = FilePath
type ServiceDir  = FilePath
type PrameterDir = FilePath

type ProjectName    = Text
type ServiceName    = Text
type ServiceVersion = Text
type MethodName     = Text
type Desc           = Text

type Required = Bool

type Gen w     = WriterT w
type GenImport = Gen (Set Import)

data Import = ImportPrelude | ImportText | ImportEnum | ImportGenerics | Import Text deriving (Eq, Ord, Show)