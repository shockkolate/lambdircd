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

module IRC
( Hostmask(..)
, Prefix(..)
, Message(..)
, ircParams
, parseMessage
) where

import Data.Char
import LeftApplication

data Hostmask = Hostmask
    { nick  :: String
    , user  :: String
    , host  :: String
    }

instance Show Hostmask where
    show (Hostmask n u h) = n ++ ('!':u) ++ ('@':h)

data Prefix = StringPrefix String | MaskPrefix Hostmask
instance Show Prefix where
    show (StringPrefix s)   = s
    show (MaskPrefix m)     = show m

data Message = Message
    { prefix    :: Maybe Prefix
    , command   :: String
    , params    :: [String]
    } deriving (Show)

ircParams :: String -> [String]
ircParams "" = []
ircParams (':':xs) = [xs]
ircParams s = x : (ircParams $ drop 1 xs)
  where (x, xs) = break isSpace s

parseMessage :: String -> Message
parseMessage "" = Message Nothing "" []
parseMessage (':':s) = Message
    $> Just (StringPrefix $ (head.words) s)
    $> (head.tail.ircParams) s
    $> (tail.tail.ircParams) s
parseMessage s = Message Nothing
    $> (head.ircParams) s
    $> (tail.ircParams) s
