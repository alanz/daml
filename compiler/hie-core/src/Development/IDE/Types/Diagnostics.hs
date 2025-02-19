-- Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
-- SPDX-License-Identifier: Apache-2.0

{-# LANGUAGE OverloadedStrings #-}

module Development.IDE.Types.Diagnostics (
  LSP.Diagnostic(..),
  FileDiagnostic,
  LSP.DiagnosticSeverity(..),
  DiagnosticStore,
  DiagnosticRelatedInformation(..),
  List(..),
  StoreItem(..),
  ideErrorText,
  ideErrorPretty,
  errorDiag,
  showDiagnostics,
  showDiagnosticsColored,
  setStageDiagnostics,
  getAllDiagnostics,
  filterDiagnostics,
  getFileDiagnostics,
  prettyDiagnostics
  ) where

import Data.Maybe as Maybe
import Data.Foldable
import qualified Data.Map as Map
import qualified Data.Text as T
import Data.Text.Prettyprint.Doc.Syntax
import qualified Data.SortedList as SL
import qualified Text.PrettyPrint.Annotated.HughesPJClass as Pretty
import qualified Language.Haskell.LSP.Types as LSP
import Language.Haskell.LSP.Types as LSP (
    DiagnosticSeverity(..)
  , Diagnostic(..)
  , List(..)
  , DiagnosticRelatedInformation(..)
  )
import Language.Haskell.LSP.Diagnostics

import Development.IDE.Types.Location


ideErrorText :: NormalizedFilePath -> T.Text -> FileDiagnostic
ideErrorText fp = errorDiag fp "Ide Error"

ideErrorPretty :: Pretty.Pretty e => NormalizedFilePath -> e -> FileDiagnostic
ideErrorPretty fp = ideErrorText fp . T.pack . Pretty.prettyShow

errorDiag :: NormalizedFilePath -> T.Text -> T.Text -> FileDiagnostic
errorDiag fp src msg =
  (fp,  diagnostic noRange LSP.DsError src msg)

-- | This is for compatibility with our old diagnostic type
diagnostic :: Range
           -> LSP.DiagnosticSeverity
           -> T.Text -- ^ source
           -> T.Text -- ^ message
           -> LSP.Diagnostic
diagnostic rng sev src msg
    = LSP.Diagnostic {
          _range = rng,
          _severity = Just sev,
          _code = Nothing,
          _source = Just src,
          _message = msg,
          _relatedInformation = Nothing
          }


-- | Human readable diagnostics for a specific file.
--
--   This type packages a pretty printed, human readable error message
--   along with the related source location so that we can display the error
--   on either the console or in the IDE at the right source location.
--
type FileDiagnostic = (NormalizedFilePath, Diagnostic)

prettyRange :: Range -> Doc SyntaxClass
prettyRange Range{..} = f _start <> "-" <> f _end
    where f Position{..} = pretty (_line+1) <> colon <> pretty _character

stringParagraphs :: T.Text -> Doc a
stringParagraphs = vcat . map (fillSep . map pretty . T.words) . T.lines

showDiagnostics :: [FileDiagnostic] -> T.Text
showDiagnostics = srenderPlain . prettyDiagnostics

showDiagnosticsColored :: [FileDiagnostic] -> T.Text
showDiagnosticsColored = srenderColored . prettyDiagnostics


prettyDiagnostics :: [FileDiagnostic] -> Doc SyntaxClass
prettyDiagnostics = vcat . map prettyDiagnostic

prettyDiagnostic :: FileDiagnostic -> Doc SyntaxClass
prettyDiagnostic (fp, LSP.Diagnostic{..}) =
    vcat
        [ slabel_ "File:    " $ pretty (fromNormalizedFilePath fp)
        , slabel_ "Range:   " $ prettyRange _range
        , slabel_ "Source:  " $ pretty _source
        , slabel_ "Severity:" $ pretty $ show sev
        , slabel_ "Message: "
            $ case sev of
              LSP.DsError -> annotate ErrorSC
              LSP.DsWarning -> annotate WarningSC
              LSP.DsInfo -> annotate InfoSC
              LSP.DsHint -> annotate HintSC
            $ stringParagraphs _message
        , slabel_ "Code:" $ pretty _code
        ]
    where
        sev = fromMaybe LSP.DsError _severity

getDiagnosticsFromStore :: StoreItem -> [Diagnostic]
getDiagnosticsFromStore (StoreItem _ diags) =
    toList =<< Map.elems diags


-- | Sets the diagnostics for a file and compilation step
--   if you want to clear the diagnostics call this with an empty list
setStageDiagnostics ::
  NormalizedFilePath ->
  Maybe Int ->
  -- ^ the time that the file these diagnostics originate from was last edited
  T.Text ->
  [LSP.Diagnostic] ->
  DiagnosticStore ->
  DiagnosticStore
setStageDiagnostics fp timeM stage diags ds  =
    updateDiagnostics ds uri timeM diagsBySource
    where
        diagsBySource = Map.singleton (Just stage) (SL.toSortedList diags)
        uri = filePathToUri' fp

getAllDiagnostics ::
    DiagnosticStore ->
    [FileDiagnostic]
getAllDiagnostics =
    concatMap (\(k,v) -> map (fromUri k,) $ getDiagnosticsFromStore v) . Map.toList

getFileDiagnostics ::
    NormalizedFilePath ->
    DiagnosticStore ->
    [LSP.Diagnostic]
getFileDiagnostics fp ds =
    maybe [] getDiagnosticsFromStore $
    Map.lookup (filePathToUri' fp) ds

filterDiagnostics ::
    (NormalizedFilePath -> Bool) ->
    DiagnosticStore ->
    DiagnosticStore
filterDiagnostics keep =
    Map.filterWithKey (\uri _ -> maybe True (keep . toNormalizedFilePath) $ uriToFilePath' $ fromNormalizedUri uri)
