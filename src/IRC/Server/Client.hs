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

module IRC.Server.Client where

import Data.Maybe
import System.IO

data Client = Client
    { uid       :: Maybe Integer
    , handle    :: Maybe Handle
    , nick      :: Maybe String
    , user      :: Maybe String
    , realName  :: Maybe String
    } deriving (Show)

defaultClient :: Client
defaultClient = Client
    { uid       = Nothing
    , handle    = Nothing
    , nick      = Nothing
    , user      = Nothing
    , realName  = Nothing
    }

isClientRegistered :: Client -> Bool
isClientRegistered client =
    isJust (nick client) &&
    isJust (user client) &&
    isJust (realName client)

sendClient :: Client -> String -> IO ()
sendClient client message = do
    hPutStr handle' $ message ++ "\r\n"
  where Just handle' = handle client
