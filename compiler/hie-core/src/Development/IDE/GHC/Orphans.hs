-- Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
-- SPDX-License-Identifier: Apache-2.0

{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

-- | Orphan instances for GHC.
--   Note that the 'NFData' instances may not be law abiding.
module Development.IDE.GHC.Orphans() where

import           GHC                         hiding (convertLit)
import           GhcPlugins                  as GHC hiding (fst3, (<>))
import qualified StringBuffer as SB
import Control.DeepSeq
import Development.IDE.GHC.Util


-- Orphan instances for types from the GHC API.
instance Show CoreModule where show = prettyPrint
instance NFData CoreModule where rnf = rwhnf


instance Show InstalledUnitId where
    show = installedUnitIdString

instance NFData InstalledUnitId where rnf = rwhnf

instance NFData SB.StringBuffer where rnf = rwhnf

instance Show Module where
    show = moduleNameString . moduleName

instance Show (GenLocated SrcSpan ModuleName) where show = prettyPrint
instance Show Name where show = prettyPrint
