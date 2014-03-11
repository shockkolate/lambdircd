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

module Part where

import Data.List
import qualified Data.Map as M
import IRC.Message
import IRC.Numeric
import qualified IRC.Server.Client as Client
import qualified IRC.Server.Channel as Chan
import IRC.Server.Channel.Helper
import IRC.Server.Environment (whenRegistered)
import qualified IRC.Server.Environment as Env
import Plugin

plugin = defaultPlugin {handlers=[("PART", part)]}

part :: CommandHandler
part env (Message _ _ (chan@('#':_):xs)) = whenRegistered env $ if M.member chan locChans
    then if elem chan channels
        then do
            let newChans = M.adjust (\c@(Chan.Channel {Chan.uids=us}) -> c {Chan.uids=delete uid us}) chan locChans
            sendChannelFromClient client env (locChans M.! chan) $ "PART " ++ chan ++ case xs of
                reason:_    -> ' ' : ':' : reason
                []          -> ""
            return env
                { Env.client=client {Client.channels=delete chan channels}
                , Env.local=local {Env.channels=newChans}
                }
        else sendNumeric env numERR_NOTONCHANNEL [chan, "You're not on that channel"] >> return env
    else sendNumeric env numERR_NOSUCHCHANNEL [chan, "No such channel"] >> return env
  where
    local = Env.local env
    locChans = Env.channels local
    client = Env.client env
    Just uid = Client.uid client
    channels = Client.channels client
part env (Message _ _ (chan:_)) = whenRegistered env $ do
    sendNumeric env numERR_BADCHANNAME [chan, "Illegal channel name"]
    return env
part env _ = whenRegistered env $ do
    sendNumeric env numERR_NEEDMOREPARAMS ["PART", "Not enough parameters"]
    return env