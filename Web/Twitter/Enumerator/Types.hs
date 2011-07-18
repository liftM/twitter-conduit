{-# LANGUAGE OverloadedStrings #-}

module Web.Twitter.Enumerator.Types
       ( DateString
       , UserId
       , URLString
       , UserName
       , StatusId
       , StreamingAPI(..)
       , Status(..)
       , RetweetedStatus(..)
       , EventTarget(..)
       , Event(..)
       , Delete(..)
       , User(..)
       )
       where

import Data.Aeson
import Data.Aeson.Types (Parser)
import Data.Text as T
import Control.Applicative
import Control.Monad

type DateString  = String
type UserId      = Integer
type URLString   = String
type UserName    = T.Text
type StatusId    = Integer

data StreamingAPI = SStatus Status
                  | SRetweetedStatus RetweetedStatus
                  | SEvent Event
                  | SDelete Delete
                  -- -- | SScrubGeo ScrubGeo
                  | SFriends Friends
                  | SUnknown Value
                  deriving (Show, Eq)

instance FromJSON StreamingAPI where
  parseJSON v@(Object o) =
    SRetweetedStatus <$> (parseJSON v :: Parser RetweetedStatus)
    <|> SStatus <$> (parseJSON v :: Parser Status)
    <|> SEvent <$> (parseJSON v :: Parser Event)
    <|> SDelete <$> (parseJSON v :: Parser Delete)
    <|> SFriends <$> (parseJSON v :: Parser Friends)
    <|> (return $ SUnknown v)
  parseJSON _ = mzero

data Status =
  Status
  { statusCreatedAt     :: DateString
  , statusId            :: StatusId
  , statusText          :: T.Text
  , statusSource        :: String
  , statusTruncated     :: Bool
  , statusInReplyTo     :: Maybe StatusId
  , statusInReplyToUser :: Maybe UserId
  , statusFavorite      :: Maybe Bool
  , statusUser          :: User
  } deriving (Show, Eq)

instance FromJSON Status where
  parseJSON (Object o) =
    Status <$> o .:  "created_at"
           <*> o .:  "id"
           <*> o .:  "text"
           <*> o .:  "source"
           <*> o .:  "truncated"
           <*> o .:? "in_reply_to_status_id"
           <*> o .:? "in_reply_to_user_id"
           <*> o .:? "favorite"
           <*> (o .: "user" >>= parseJSON)
  parseJSON _ = mzero

data RetweetedStatus =
  RetweetedStatus
  { rsCreatedAt       :: DateString
  , rsId              :: StatusId
  , rsText            :: T.Text
  , rsSource          :: String
  , rsTruncated       :: Bool
  , rsUser            :: User
  , rsRetweetedStatus :: Status
  } deriving (Show, Eq)

instance FromJSON RetweetedStatus where
  parseJSON (Object o) =
    RetweetedStatus <$> o .: "created_at"
                    <*> o .:  "id"
                    <*> o .:  "text"
                    <*> o .:  "source"
                    <*> o .:  "truncated"
                    <*> (o .: "user" >>= parseJSON)
                    <*> (o .: "retweeted_status" >>= parseJSON)
  parseJSON _ = mzero

data EventType = Favorite | Unfavorite
               | ListCreated | ListUpdated | ListMemberAdded
               | UserUpdate | Block | Unblock | Follow
               deriving (Show, Eq)

-- unrecogernized
data EventTarget = ETUser User | ETStatus Status | ETUnknown Value
                 deriving (Show, Eq)

instance FromJSON EventTarget where
  parseJSON v@(Object o) =
    (ETUser <$> (parseJSON v :: Parser User)) <|>
    (ETStatus <$> (parseJSON v :: Parser Status)) <|>
    (return $ ETUnknown v)
  parseJSON _ = mzero

data Event =
  Event
  { evCreatedAt       :: DateString
  , evTargetObject    :: EventTarget
  , evEvent           :: String
  , evTarget          :: EventTarget
  , evSource          :: EventTarget
  } deriving (Show, Eq)

instance FromJSON Event where
  parseJSON (Object o) =
    Event <$> o .: "created_at"
          <*> o .: "target_object"
          <*> o .: "event"
          <*> o .: "target"
          <*> o .: "source"
  parseJSON _ = mzero

data Delete =
  Delete
  { delId  :: StatusId
  , delUserId :: String
  }
  deriving (Show, Eq)

instance FromJSON Delete where
  parseJSON (Object o) = do
    s <- o .: "status"
    Delete <$> s .: "id"
           <*> s .: "user_id"
  parseJSON _ = mzero

type Friends = [UserId]

data User =
  User
  { userId              :: UserId
  , userName            :: UserName
  , userScreenName      :: String
  , userDescription     :: T.Text
  , userLocation        :: T.Text
  , userProfileImageURL :: Maybe URLString
  , userURL             :: Maybe URLString
  , userProtected       :: Maybe Bool
  , userFollowers       :: Maybe Int
  } deriving (Show, Eq)

instance FromJSON User where
  parseJSON (Object o) =
    User <$> o .:  "id"
         <*> o .:  "name"
         <*> o .:  "screen_name"
         <*> o .:  "description"
         <*> o .:  "location"
         <*> o .:? "profile_image_url"
         <*> o .:? "url"
         <*> o .:? "protected"
         <*> o .:? "followers_count"
  parseJSON _ = mzero
