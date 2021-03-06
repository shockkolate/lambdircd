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

module MaxChannels where

import IRC.Numeric
import IRC.Action
import qualified IRC.Server.Client as Client
import qualified IRC.Server.Environment as Env
import Config
import Plugin

plugin = defaultPlugin {handlers=[TransformHandler trans]}

trans :: TransformHSpec
trans env = env {Env.actions=map f (Env.actions env)}
  where
    maxChans = getConfigInt (Env.config env) "client" "max_channels"
    channels = Client.channels (Env.client env)
    f a@(ChanAction "Join" chan _) = if length channels < maxChans
        then a
        else GenericAction $ \e -> sendNumeric e numERR_TOOMANYCHANNELS [chan, "You have joined too many channels"]
            >> return e
    f a = a
