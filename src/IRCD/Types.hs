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

module IRCD.Types where

import qualified Data.Map as M (Map, empty)
import qualified Data.IntMap as IM (IntMap, empty)
import Control.Monad.State
import System.IO (Handle)

data Message = Message
    { tags      :: () -- TODO: support message tags
    , prefix    :: Maybe Prefix
    , command   :: String
    , params    :: [String]
    } deriving Show

data Prefix = StringPrefix String
            | MaskPrefix Hostmask
              deriving Eq

instance Show Prefix where
    show (StringPrefix p) = p
    show (MaskPrefix p) = show p

data Hostmask = Hostmask
    { maskNick  :: String
    , maskUser  :: String
    , maskHost  :: String
    } deriving Eq

instance Show Hostmask where show (Hostmask n u h) = n ++ '!' : u ++ '@' : h

data Client = Client
    { uid           :: Int
    , handle        :: Maybe Handle
    , registered    :: Bool
    , nick          :: Maybe String
    , user          :: Maybe String
    , realName      :: Maybe String
    , host          :: Maybe String
    , channels      :: [Channel]
    } deriving (Show, Eq)

data Clients = Clients
    { byUid     :: IM.IntMap Client
    , byNick    :: M.Map String Client
    } deriving Show

data Channel = Channel
    { name    :: String
    , modes   :: [Char]
    , clients :: [Client]
    } deriving (Show, Eq)

data Source = ClientSrc Client deriving Show
data Destination = ChannelDst Channel deriving Show

data Env = Env
    { envClients        :: Clients
    , envHandlers       :: [Handler]
    , envTransformers   :: [Transformer]
    }

data Plugin = Plugin
    { pluginName    :: String
    , startup       :: StateT Env IO ()
    , shutdown      :: StateT Env IO ()
    , handlers      :: [Handler]
    , transformers  :: [Transformer]
    }

type HandlerSpec = Source -> Message -> State Env [Action]
data Handler = GenericHandler HandlerSpec
             | CommandHandler String HandlerSpec

type TransformerSpec = Action -> State Env (Bool, [Action])
data Transformer = Transformer TransformerSpec Int

instance Show Transformer where
    show (Transformer _ order) = "Transformer <fn>" ++ show order

instance Eq Transformer where
    Transformer _ x == Transformer _ y = x == y

instance Ord Transformer where
    Transformer _ x `compare` Transformer _ y = x `compare` y

type ActionSpec = StateT Env IO ()
data Action = GenericAction ActionSpec
            | PrivmsgAction Source Destination Message ActionSpec
            | NickChangeAction Source (Maybe String) String ActionSpec
            | UserChangeAction Source (Maybe String) String ActionSpec
            | RealNameChangeAction Source (Maybe String) String ActionSpec
            | RegisterAction Source ActionSpec

instance Show Action where
    show (GenericAction _) = "GenericAction <fn>"
    show (PrivmsgAction src dst msg _) = "PrivmsgAction " ++ show src ++ ' ' : show dst ++ ' ' : show msg ++ " <fn>"
    show (NickChangeAction src old new _) = "NickChangeAction " ++ show src ++ ' ' : show old ++ ' ' : new ++ " <fn>"
    show (UserChangeAction src old new _) = "UserChangeAction " ++ show src ++ ' ' : show old ++ ' ' : new ++ " <fn>"
    show (RealNameChangeAction src old new _) = "RealNameChangeAction " ++ show src ++ ' ' : show old ++ ' ' : new ++ " <fn>"
    show (RegisterAction src _) = "RegisterAction " ++ show src ++ " <fn>"

actionSpec :: Action -> ActionSpec
actionSpec (GenericAction spec) = spec
actionSpec (PrivmsgAction _ _ _ spec) = spec
actionSpec (NickChangeAction _ _ _ spec) = spec
actionSpec (UserChangeAction _ _ _ spec) = spec
actionSpec (RealNameChangeAction _ _ _ spec) = spec
actionSpec (RegisterAction _ spec) = spec

defaultClient :: Int -> Client
defaultClient uid' = Client
    { uid           = uid'
    , handle        = Nothing
    , registered    = False
    , nick          = Nothing
    , user          = Nothing
    , realName      = Nothing
    , host          = Nothing
    , channels      = []
    }

defaultClients :: Clients
defaultClients = Clients
    { byUid     = IM.empty
    , byNick    = M.empty
    }

defaultEnv :: Env
defaultEnv = Env
    { envClients        = defaultClients
    , envHandlers       = []
    , envTransformers   = []
    }

defaultPlugin :: Plugin
defaultPlugin = Plugin
    { pluginName    = ""
    , startup       = return ()
    , shutdown      = return ()
    , handlers      = []
    , transformers  = []
    }

defaultTransformer :: TransformerSpec -> Transformer
defaultTransformer f = Transformer f 100
