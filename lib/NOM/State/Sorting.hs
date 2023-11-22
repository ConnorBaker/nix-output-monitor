module NOM.State.Sorting (
  sortDepsOfSet,
  summaryIncludingRoot,
  sortKey,
  SortKey,
) where

import Control.Monad.Extra (pureIf)
import Data.List.Extra (firstJust)
import Data.MemoTrie (memo)
import Data.Sequence.Strict qualified as Seq
import NOM.State (
  BuildFail (..),
  BuildInfo (..),
  BuildStatus (Unknown),
  DependencySummary (..),
  DerivationId,
  DerivationInfo (..),
  DerivationSet,
  InputDerivation (..),
  NOMState,
  NOMV1State (..),
  StorePathInfo (..),
  TransferInfo (..),
  getDerivationInfos,
  getStorePathInfos,
  updateSummaryForDerivation,
  updateSummaryForStorePath,
 )
import NOM.State.CacheId.Map qualified as CMap
import NOM.State.CacheId.Set qualified as CSet
import NOM.Util (foldMapEndo)
import Optics (gfield, (%~))
import Relude
import Safe.Foldable (minimumMay)

sortDepsOfSet :: DerivationSet -> NOMState ()
sortDepsOfSet parents = do
  currentState <- get
  let sort_parent :: DerivationId -> NOMState ()
      sort_parent drvId = do
        drvInfo <- getDerivationInfos drvId
        let newDrvInfo = (gfield @"inputDerivations" %~ sort_derivations) drvInfo
        modify' (gfield @"derivationInfos" %~ CMap.insert drvId newDrvInfo)
      sort_derivations :: Seq InputDerivation -> Seq InputDerivation
      sort_derivations = Seq.sortOn (sort_key . (.derivation))

      sort_key :: DerivationId -> SortKey
      sort_key = memo (sortKey currentState)
  mapM_ (\drvId -> sort_parent drvId) $ CSet.toList parents

type SortKey =
  ( SortOrder -- First sort by the state of this build
  , SortOrder -- Sort by the most important kind of build for all children
  , -- We always want to show all running builds and transfers so we try to display them low in the tree.
    Down Int -- Running Builds, prefer more
  , Down Int -- Running Downloads, prefer more
  -- But we want to show the smallest tree showing all builds and downloads to save screen estate.
  , Int -- Waiting Builds and Downloads, prefer less
  )

data SortOrder
  = -- First the failed builds starting with the earliest failures
    SFailed Double
  | -- Second the running builds starting with longest running
    SBuilding Double
  | -- The longer a download is running, the more it matters.
    SDownloading Double
  | -- The longer an upload is running, the more it matters.
    SUploading Double
  | SWaiting
  | SDownloadWaiting
  | -- The longer a build is completed the less it matters
    SDone (Down Double)
  | -- The longer a download is completed the less it matters
    SDownloaded (Down Double)
  | -- The longer an upload is completed the less it matters
    SUploaded (Down Double)
  | SUnknown
  deriving stock (Eq, Show, Ord)

summaryIncludingRoot :: DerivationId -> NOMState DependencySummary
summaryIncludingRoot drvId = do
  MkDerivationInfo{dependencySummary, buildStatus} <- getDerivationInfos drvId
  pure (updateSummaryForDerivation Unknown buildStatus drvId dependencySummary)

summaryOnlyThisNode :: DerivationId -> NOMState DependencySummary
summaryOnlyThisNode drvId = do
  MkDerivationInfo{outputs, buildStatus} <- getDerivationInfos drvId
  output_infos <- mapM (\x -> (x,) <$> getStorePathInfos x) (toList outputs)
  pure
    $ foldMapEndo
      ( \(output_id, output_info) ->
          updateSummaryForStorePath mempty output_info.states output_id
      )
      output_infos
    . updateSummaryForDerivation Unknown buildStatus drvId
    $ mempty

sortOrder :: DependencySummary -> SortOrder
sortOrder MkDependencySummary{..} = fromMaybe SUnknown (firstJust id sort_entries)
 where
  sort_entries =
    [ SFailed <$> minimumMay ((.at) . (.end) <$> failedBuilds)
    , SBuilding <$> minimumMay ((.start) <$> runningBuilds)
    , SDownloading <$> minimumMay ((.start) <$> runningDownloads)
    , SUploading <$> minimumMay ((.start) <$> runningUploads)
    , pureIf (not (CSet.null plannedBuilds)) SWaiting
    , pureIf (not (CSet.null plannedDownloads)) SDownloadWaiting
    , SDone <$> minimumMay (Down . (.end) <$> completedBuilds)
    , SDownloaded <$> minimumMay (Down . (.start) <$> completedDownloads)
    , SUploaded <$> minimumMay (Down . (.start) <$> completedUploads)
    ]

sortKey :: NOMV1State -> DerivationId -> SortKey
sortKey nom_state drvId =
  let (only_this_summary, summary@MkDependencySummary{..}) = evalState ((,) <$> summaryOnlyThisNode drvId <*> summaryIncludingRoot drvId) nom_state
   in (sortOrder only_this_summary, sortOrder summary, Down (CMap.size runningBuilds), Down (CMap.size runningDownloads), CSet.size plannedBuilds + CSet.size plannedDownloads)
