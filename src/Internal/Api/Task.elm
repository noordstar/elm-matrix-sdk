module Internal.Api.Task exposing (..)

{-| This module contains all tasks that can be executed.
-}

import Hash
import Internal.Api.Chain as Chain
import Internal.Api.Credentials exposing (Credentials)
import Internal.Api.GetEvent.Main exposing (EventInput)
import Internal.Api.Invite.Main exposing (InviteInput)
import Internal.Api.JoinedMembers.Main exposing (JoinedMembersInput)
import Internal.Api.SendStateKey.Main exposing (SendStateKeyInput)
import Internal.Api.Sync.Main exposing (SyncInput)
import Internal.Api.VaultUpdate as C
import Json.Encode as E


type alias FutureTask =
    C.FutureTask


getEvent : EventInput -> Credentials -> FutureTask
getEvent data cred =
    C.makeVBA cred
        |> Chain.andThen (C.getEvent data)
        |> C.toTask


invite : InviteInput -> Credentials -> FutureTask
invite data cred =
    C.makeVBA cred
        |> Chain.andThen (C.invite data)
        |> C.toTask


joinedMembers : JoinedMembersInput -> Credentials -> FutureTask
joinedMembers data cred =
    C.makeVBA cred
        |> Chain.andThen (C.joinedMembers data)
        |> C.toTask


type alias RedactInput =
    { eventId : String
    , extraTransactionNoise : String
    , reason : Maybe String
    , roomId : String
    }


redact : RedactInput -> Credentials -> FutureTask
redact { eventId, extraTransactionNoise, reason, roomId } cred =
    cred
        |> C.makeVBAT
            (\now ->
                [ Hash.fromInt now
                , Hash.fromString eventId
                , Hash.fromString extraTransactionNoise
                , Hash.fromString (reason |> Maybe.withDefault "noreason")
                , Hash.fromString roomId
                ]
                    |> List.foldl Hash.independent (Hash.fromString "redact")
                    |> Hash.toString
            )
        |> Chain.andThen (C.redact { eventId = eventId, reason = reason, roomId = roomId })
        |> Chain.andThen
            (Chain.maybe <| C.getEvent { eventId = eventId, roomId = roomId })
        |> C.toTask


type alias SendMessageEventInput =
    { content : E.Value
    , eventType : String
    , extraTransactionNoise : String
    , roomId : String
    }


sendMessageEvent : SendMessageEventInput -> Credentials -> FutureTask
sendMessageEvent { content, eventType, extraTransactionNoise, roomId } cred =
    cred
        |> C.makeVBAT
            (\now ->
                [ Hash.fromInt now
                , Hash.fromString (E.encode 0 content)
                , Hash.fromString eventType
                , Hash.fromString extraTransactionNoise
                , Hash.fromString roomId
                ]
                    |> List.foldl Hash.independent (Hash.fromString "send message")
                    |> Hash.toString
            )
        |> Chain.andThen (C.sendMessageEvent { content = content, eventType = eventType, roomId = roomId })
        -- TODO: Get event from API to see what it looks like
        |> C.toTask


sendStateEvent : SendStateKeyInput -> Credentials -> FutureTask
sendStateEvent data cred =
    C.makeVBA cred
        |> Chain.andThen (C.sendStateEvent data)
        -- TODO: Get event from API to see what it looks like
        |> C.toTask


sync : SyncInput -> Credentials -> FutureTask
sync data cred =
    C.makeVBA cred
        |> Chain.andThen (C.sync data)
        |> C.toTask
