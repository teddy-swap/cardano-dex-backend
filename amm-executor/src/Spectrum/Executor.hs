{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UndecidableInstances #-}

module Spectrum.Executor
  ( runApp
  ) where

import RIO
  ( ReaderT (..), MonadReader (ask), MonadIO (liftIO), void, Alternative (..), MonadPlus (..) )
import RIO.List
  ( headMaybe )

import System.Posix.Signals
  ( Handler (..)
  , installHandler
  , keyboardSignal
  , raiseSignal
  , softwareTermination
  )

import qualified Control.Concurrent.STM.TBQueue as STM
import qualified Control.Concurrent.STM.TMVar   as STM
import qualified Control.Concurrent.STM.TQueue  as STM
import qualified Control.Concurrent.STM.TVar    as STM
import qualified Control.Monad.STM              as STM
import qualified Control.Concurrent.Async       as Async

import GHC.Generics
  ( Generic )

import Data.Aeson
  ( encode )
import Data.ByteString.Lazy.UTF8
  ( toString )

import Control.Monad.Class.MonadSTM
  ( MonadSTM (..) )
import Control.Monad.Class.MonadST
  ( MonadST )
import Control.Monad.Class.MonadAsync
  ( MonadAsync (..) )
import Control.Monad.Class.MonadFork
  ( MonadThread, MonadFork )
import Control.Monad.Trans.Control
  ( MonadBaseControl )
import Control.Monad.Base
  ( MonadBase )
import Control.Monad.Class.MonadThrow
  ( MonadThrow, MonadMask, MonadCatch )
import Control.Monad.Trans.Resource
  ( ResourceT, runResourceT, MonadUnliftIO )
import Control.Monad.Trans.Class
  ( MonadTrans(lift) )
import qualified Control.Monad.Catch as MC


import Control.Tracer
  ( stdoutTracer, Contravariant (contramap) )
import System.Logging.Hlog
  ( makeLogging, MakeLogging, translateMakeLogging )

import Streamly.Prelude as S (drain, SerialT)

import Spectrum.LedgerSync.Config
  ( NetworkParameters, LedgerSyncConfig, parseNetworkParameters )
import Spectrum.LedgerSync
  ( mkLedgerSync )
import Cardano.Network.Protocol.NodeToClient.Trace
  ( encodeTraceClient )
import Spectrum.Executor.EventSource.Stream
  ( mkEventSource, EventSource (upstream) )
import Spectrum.Executor.Config
  ( AppConfig(..), loadAppConfig, EventSourceConfig )
import Spectrum.Executor.EventSource.Persistence.Config
  ( LedgerStoreConfig )
import Spectrum.Executor.EventSink.Pipe (mkEventSink, pipe)
import Spectrum.Executor.EventSink.Types (voidEventHandler)
import Spectrum.Executor.EventSink.Handlers.Pools (mkNewPoolsHandler)
import Spectrum.Executor.EventSink.Handlers.Orders (mkPendingOrdersHandler)

data Env f m = Env
  { ledgerSyncConfig   :: !LedgerSyncConfig
  , eventSourceConfig  :: !EventSourceConfig
  , lederHistoryConfig :: !LedgerStoreConfig
  , networkParams      :: !NetworkParameters
  , mkLogging          :: !(MakeLogging f m)
  , mkLogging'         :: !(MakeLogging m m)
  } deriving stock (Generic)

newtype App a = App
  { unApp :: ReaderT (Env Wire App) IO a
  } deriving newtype
    ( Functor, Applicative, Monad
    , MonadReader (Env Wire App)
    , MonadIO
    , MonadST
    , MonadThread, MonadFork
    , MonadThrow, MC.MonadThrow, MonadCatch, MonadMask
    , MonadBase IO, MonadBaseControl IO, MonadUnliftIO
    )

type Wire = ResourceT App

runApp :: [String] -> IO ()
runApp args = do
  AppConfig{..} <- loadAppConfig $ headMaybe args
  nparams       <- parseNetworkParameters nodeConfigPath
  mkLogging     <- makeLogging loggingConfig
  let
    env =
      Env ledgerSyncConfig eventSourceConfig ledgerStoreConfig nparams
        (translateMakeLogging (lift . App . lift) mkLogging)
        (translateMakeLogging (App . lift) mkLogging)
  runContext env (runResourceT wireApp)

wireApp :: Wire ()
wireApp = interceptSigTerm >> do
  env <- ask
  let tr = contramap (toString . encode . encodeTraceClient) stdoutTracer
  lsync <- lift $ mkLedgerSync (runContext env) tr
  source <- mkEventSource lsync
  let
    poolsHan = mkNewPoolsHandler @App undefined
    orderHan = mkPendingOrdersHandler @App undefined
    sink = mkEventSink @SerialT @App [poolsHan, orderHan] voidEventHandler
  lift . S.drain . pipe sink . upstream $ source

runContext :: Env Wire App -> App a -> IO a
runContext env app = runReaderT (unApp app) env

interceptSigTerm :: Wire ()
interceptSigTerm =
    lift $ liftIO $ void $ installHandler softwareTermination handler Nothing
  where
    handler = CatchOnce $ raiseSignal keyboardSignal

newtype WrappedSTM a = WrappedSTM { unwrapSTM :: STM.STM a }
    deriving newtype (Functor, Applicative, Alternative, Monad, MonadPlus, MonadThrow)

instance MonadSTM App where
  type STM     App = WrappedSTM
  type TVar    App = STM.TVar
  type TMVar   App = STM.TMVar
  type TQueue  App = STM.TQueue
  type TBQueue App = STM.TBQueue

  atomically      = App . lift . STM.atomically . unwrapSTM
  retry           = WrappedSTM STM.retry
  orElse          = \a0 a1 -> WrappedSTM (STM.orElse (unwrapSTM a0) (unwrapSTM a1))
  check           = WrappedSTM . STM.check

  newTVar         = WrappedSTM . STM.newTVar
  newTVarIO       = App . lift . STM.newTVarIO
  readTVar        = WrappedSTM . STM.readTVar
  readTVarIO      = App . lift . STM.readTVarIO
  writeTVar       = \a0 -> WrappedSTM . STM.writeTVar a0
  modifyTVar      = \a0 -> WrappedSTM . STM.modifyTVar a0
  modifyTVar'     = \a0 -> WrappedSTM . STM.modifyTVar' a0
  stateTVar       = \a0 -> WrappedSTM . STM.stateTVar a0
  swapTVar        = \a0 -> WrappedSTM . STM.swapTVar a0

  newTMVar        = WrappedSTM . STM.newTMVar
  newTMVarIO      = App . lift . STM.newTMVarIO
  newEmptyTMVar   = WrappedSTM STM.newEmptyTMVar
  newEmptyTMVarIO = App (lift STM.newEmptyTMVarIO)
  takeTMVar       = WrappedSTM . STM.takeTMVar
  tryTakeTMVar    = WrappedSTM . STM.tryTakeTMVar
  putTMVar        = \a0 -> WrappedSTM . STM.putTMVar a0
  tryPutTMVar     = \a0 -> WrappedSTM . STM.tryPutTMVar a0
  readTMVar       = WrappedSTM . STM.readTMVar
  tryReadTMVar    = WrappedSTM . STM.tryReadTMVar
  swapTMVar       = \a0 -> WrappedSTM . STM.swapTMVar a0
  isEmptyTMVar    = WrappedSTM . STM.isEmptyTMVar

  newTQueue       = WrappedSTM STM.newTQueue
  newTQueueIO     = App (lift STM.newTQueueIO)
  readTQueue      = WrappedSTM . STM.readTQueue
  tryReadTQueue   = WrappedSTM . STM.tryReadTQueue
  peekTQueue      = WrappedSTM . STM.peekTQueue
  tryPeekTQueue   = WrappedSTM . STM.tryPeekTQueue
  flushTBQueue    = WrappedSTM . STM.flushTBQueue
  writeTQueue     = \a0 -> WrappedSTM . STM.writeTQueue a0
  isEmptyTQueue   = WrappedSTM . STM.isEmptyTQueue

  newTBQueue      = WrappedSTM . STM.newTBQueue
  newTBQueueIO    = App . lift . STM.newTBQueueIO
  readTBQueue     = WrappedSTM . STM.readTBQueue
  tryReadTBQueue  = WrappedSTM . STM.tryReadTBQueue
  peekTBQueue     = WrappedSTM . STM.peekTBQueue
  tryPeekTBQueue  = WrappedSTM . STM.tryPeekTBQueue
  writeTBQueue    = \a0 -> WrappedSTM . STM.writeTBQueue a0
  lengthTBQueue   = WrappedSTM . STM.lengthTBQueue
  isEmptyTBQueue  = WrappedSTM . STM.isEmptyTBQueue
  isFullTBQueue   = WrappedSTM . STM.isFullTBQueue

newtype WrappedAsync a = WrappedAsync { unwrapAsync :: Async.Async a }
    deriving newtype (Functor)

instance MonadAsync App where
  type Async App  = WrappedAsync
  async           = \(App (ReaderT m)) -> App (ReaderT $ \r -> WrappedAsync <$> async (m r))
  asyncThreadId   = Async.asyncThreadId . unwrapAsync
  pollSTM         = WrappedSTM . Async.pollSTM . unwrapAsync
  waitCatchSTM    = WrappedSTM . Async.waitCatchSTM . unwrapAsync
  cancel          = App . lift . Async.cancel . unwrapAsync
  cancelWith      = \a0 -> App . lift . Async.cancelWith (unwrapAsync a0)
  asyncWithUnmask = \restore -> App $ ReaderT $ \r ->
      fmap WrappedAsync $ Async.asyncWithUnmask $ \unmask ->
        runReaderT (unApp (restore (liftF unmask))) r
    where
      liftF :: (IO a -> IO a) -> App a -> App a
      liftF g (App (ReaderT f)) = App (ReaderT (g . f))