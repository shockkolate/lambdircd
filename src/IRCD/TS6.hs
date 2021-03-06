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

module IRCD.TS6 (intToID) where

import Numeric (showIntAtBase)
import Data.Char (intToDigit)
import Text.Printf (printf)

intToID :: Int -> String
intToID x = 'A' : printf "%05s" (showIntAtBase 36 toChr x "")
  where toChr c
            | 0 <= c && c <= 9 = intToDigit c
            | otherwise = toEnum (c + (65 - 10))
