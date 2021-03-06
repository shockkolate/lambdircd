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

module IRC.Server.Client.Helper where

import Data.Maybe
import System.IO
import System.IO.Error
import qualified IRC.Hostmask as H
import IRC.Server.Client

whenClientRegistered :: Client -> a -> a -> a
whenClientRegistered client x y
    | registered client = y
    | otherwise = x

isClientReady :: Client -> Bool
isClientReady client =
    isJust (nick client) &&
    isJust (user client) &&
    isJust (realName client)

clientToMask :: Client -> H.Hostmask
clientToMask client = H.Hostmask n u h
  where
    Just n = nick client
    Just u = user client
    Just h = host client

sendClient :: Client -> String -> IO ()
sendClient client message = do
    tryIOError $ hPutStr handle' $ message ++ "\r\n"
    return ()
  where Just handle' = handle client

sendClientFrom :: String -> Client -> String -> IO ()
sendClientFrom mask client message = sendClient client newMessage
  where newMessage = ':' : mask ++ ' ' : message
