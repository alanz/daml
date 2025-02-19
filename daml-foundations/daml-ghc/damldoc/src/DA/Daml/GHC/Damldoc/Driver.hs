-- Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
-- SPDX-License-Identifier: Apache-2.0

{-# LANGUAGE OverloadedStrings #-}

module DA.Daml.GHC.Damldoc.Driver(
    damlDocDriver,
    InputFormat(..), DocFormat(..)
    , DocOption(..)
    ) where

import           DA.Daml.GHC.Damldoc.Types
import           DA.Daml.GHC.Damldoc.Render
import           DA.Daml.GHC.Damldoc.HaddockParse
import           DA.Daml.GHC.Damldoc.Transform
import DA.Daml.GHC.Compiler.Options
import Development.IDE.Types.Location

import Development.IDE.Types.Diagnostics

import           Control.Monad.Extra
import           Control.Monad.Except
import qualified Data.Aeson                        as AE
import qualified Data.Aeson.Encode.Pretty          as AP
import qualified Data.ByteString.Lazy              as BS
import qualified Data.Text                         as T
import qualified Data.Text.Encoding                as T
import           System.Directory
import           System.FilePath


data InputFormat = InputJson | InputDaml
    deriving (Eq, Show, Read)

damlDocDriver :: InputFormat
              -> FilePath
              -> DocFormat
              -> Maybe FilePath
              -> [DocOption]
              -> [NormalizedFilePath]
              -> IO ()
damlDocDriver cInputFormat output cFormat prefixFile options files = do

    let printAndExit errMsg = do
            putStrLn $ "Error processing input from " <> unwords (map fromNormalizedFilePath files) <> "\n"
                     <> errMsg
            fail "Aborted."

    let onErrorExit act =
            act >>= either (printAndExit . renderDiags) pure
        renderDiags = T.unpack . showDiagnosticsColored

    docData <- case cInputFormat of
            InputJson -> do
                input <- mapM (BS.readFile . fromNormalizedFilePath) files
                let mbData = map AE.eitherDecode input :: [Either String [ModuleDoc]]
                concatMapM (either printAndExit pure) mbData

            InputDaml -> do
                ghcOpts <- defaultOptionsIO Nothing
                onErrorExit $ runExceptT
                            $ fmap (applyTransform options)
                            $ mkDocs (toCompileOpts ghcOpts) files

    prefix <- maybe (pure "") BS.readFile prefixFile

    let write file contents = do
            createDirectoryIfMissing True $ takeDirectory file
            putStrLn $ "Writing " ++ file ++ "..."
            BS.writeFile file $ prefix <> BS.fromStrict (T.encodeUtf8 contents)

    case cFormat of
            Json -> write output $ T.decodeUtf8 . BS.toStrict $ AP.encodePretty' jsonConf docData
            Rst  -> write output $ T.concat $ map renderSimpleRst docData
            Hoogle   -> write output $ T.concat $ map renderSimpleHoogle docData
            Markdown -> write output $ T.concat $ map renderSimpleMD docData
            Html -> sequence_
                [ write (output </> hyphenated md_name <> ".html") $ renderSimpleHtml m
                | m@ModuleDoc{..} <- docData ]
                    where hyphenated = T.unpack . T.replace "." "-"
    putStrLn "Done"
