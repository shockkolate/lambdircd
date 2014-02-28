{- Copyright 2014 David Farrell <shokku.ra@gmail.com>

 - Licensed under the Apache License, Version 2.0 (the "License");
 - you may not use this file except in compliance with the License.
 - You may obtain a copy of the License at

 - http://www.apache.org/licenses/LICENSE-2.0

 - Unless required by applicable law or agreed to in writing, software
 - distributed under the License is distributed on an "AS IS" BASIS,
 - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 - See the License for the specific language governing permissions and
 - limitations under the License.
 -}

module IRC.Server
( serveIRC
) where

import Data.Maybe
import qualified Data.Map as M
import Control.Concurrent (forkIO)
import Control.Concurrent.STM
import System.IO
import System.IO.Error
import System.Timeout
import Network
import Network.Socket hiding (accept)
import IRC.Message
import IRC.Server.Client (isClientRegistered, sendClient)
import qualified IRC.Server.Client as Client
import qualified IRC.Server.Options as Opts
import qualified IRC.Server.Environment as Env
import qualified Plugin as P
import Plugin.Load

serveIRC :: Env.Env -> IO ()
serveIRC env = withSocketsDo $ do
    plugins <- mapM loadPlugin pluginNames
    sharedT <- atomically $ newTVar Env.defaultShared
    let handlers = M.unions $ map (M.fromList.P.handlers) (catMaybes plugins)
    let newEnv = env {Env.handlers=handlers, Env.shared=Just sharedT}

    sock <- socket AF_INET Stream defaultProtocol
    setSocketOption sock ReuseAddr 1
    setSocketOption sock (CustomSockOpt (6, 9)) 30
    bindSocket sock (SockAddrInet port iNADDR_ANY)
    listen sock 5

    acceptLoop sock newEnv
  where Env.Env {Env.options=Opts.Options {Opts.plugins=pluginNames, Opts.port=port}} = env

acceptLoop :: Socket -> Env.Env-> IO ()
acceptLoop sock env = do
    (handle, hostname, _) <- accept sock
    hSetNewlineMode handle universalNewlineMode
    hSetBuffering handle LineBuffering
    hSetEncoding handle utf8

    let newEnv = env {Env.client=Client.defaultClient {Client.handle=Just handle}}

    forkIO (serveClient newEnv)
    acceptLoop sock env

serveClient :: Env.Env -> IO ()
serveClient env = do
    shared <- atomically $ readTVar sharedT
    let uid = if M.null (Env.clients shared) then 1
        else fst (M.findMax (Env.clients shared)) + 1

    tryIOError $ do
        maybeEnv <- timeout (toMicro connectTimeout) $ registerClient env
            {Env.client=client {Client.uid=Just uid}}
        case maybeEnv of
            Just newEnv -> do
                sendClient newClient $ ":lambdircd 001 "++nick++" :Welcome to lambdircd "++nick
                loopClient newEnv False
              where
                newClient = Env.client newEnv
                Just nick = Client.nick newClient
            Nothing -> return ()
    atomically $ do
        shared <- readTVar sharedT
        let newClients = M.delete uid (Env.clients shared)
        writeTVar sharedT shared {Env.clients=newClients}
  where
    Just sharedT = Env.shared env
    client = Env.client env
    Env.Env {Env.options=Opts.Options {Opts.connectTimeout=connectTimeout}} = env

registerClient :: Env.Env -> IO Env.Env
registerClient env = do
    line <- hGetLine handle
    let msg = parseMessage line
    case M.lookup (command msg) (Env.handlers env) of
        Just handler -> do
            newEnv <- handler env msg
            case isClientRegistered (Env.client newEnv) of
                True    -> return newEnv
                False   -> registerClient newEnv
        Nothing -> registerClient env
  where Just handle = Client.handle (Env.client env)

loopClient :: Env.Env -> Bool -> IO ()
loopClient env pinged = do
    maybeEnv <- timeout (toMicro pingTimeout) (handleLine env)
    case maybeEnv of
        Just newEnv -> loopClient newEnv False
        Nothing     -> case pinged of
            True        -> return ()
            False       -> sendClient client "PING :lambdircd"
                            >> loopClient env True
  where
    pingTimeout = Opts.pingTimeout (Env.options env)
    client = Env.client env

handleLine :: Env.Env -> IO Env.Env
handleLine env = do
    atomically $ do
        shared <- readTVar sharedT
        let newClients = M.insert uid client (Env.clients shared)
        writeTVar sharedT shared {Env.clients=newClients}
    line <- hGetLine handle
    let msg = parseMessage line
    case M.lookup (command msg) (Env.handlers env) of
        Just handler -> do
            let newEnv = handler env msg
            newEnv
        Nothing -> do
            sendClient client $ ":lambdircd 431 " ++ nick ++ (' ':(command msg)) ++ " :Unknown command"
            handleLine env
  where
    Just sharedT = Env.shared env
    client = Env.client env
    Just uid = Client.uid client
    Just handle = Client.handle client
    Just nick = Client.nick client
    -- force thread crash if Nothing which should never happen here

toMicro :: Num a => a -> a
toMicro = (*1000000)
