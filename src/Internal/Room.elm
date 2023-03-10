module Internal.Room exposing (..)

{-| The `Room` type represents a Matrix Room. In here, you will find utilities to ask information about a room.
-}

import Dict
import Internal.Api.Credentials as Credentials exposing (Credentials)
import Internal.Api.Sync.V2.SpecObjects as Sync
import Internal.Api.Task as Api
import Internal.Api.VaultUpdate exposing (VaultUpdate)
import Internal.Event as Event exposing (Event)
import Internal.Tools.Exceptions as X
import Internal.Tools.Hashdict as Hashdict
import Internal.Values.Event as IEvent
import Internal.Values.Room as Internal
import Internal.Values.StateManager as StateManager
import Internal.Values.Timeline as Timeline
import Json.Encode as E
import Task exposing (Task)


{-| The `Room` type represents a Matrix Room. It contains context information
such as the `accessToken` that allows the retrieval of new information from
the Matrix API if necessary.

The `Room` type contains utilities to inquire about the room and send messages
to it.

-}
type Room
    = Room
        { room : Internal.IRoom
        , context : Credentials
        }


{-| Create a new object from a joined room.
-}
initFromJoinedRoom : { roomId : String, nextBatch : String } -> Sync.JoinedRoom -> Internal.IRoom
initFromJoinedRoom data jroom =
    Internal.IRoom
        { accountData =
            jroom.accountData
                |> Maybe.map .events
                |> Maybe.withDefault []
                |> List.map (\{ contentType, content } -> ( contentType, content ))
                |> Dict.fromList
        , ephemeral =
            jroom.ephemeral
                |> Maybe.map .events
                |> Maybe.withDefault []
                |> List.map IEvent.BlindEvent
        , events =
            jroom.timeline
                |> Maybe.map .events
                |> Maybe.withDefault []
                |> List.map (Event.initFromClientEventWithoutRoomId data.roomId)
                |> Hashdict.fromList IEvent.eventId
        , roomId = data.roomId
        , timeline =
            jroom.timeline
                |> Maybe.map
                    (\timeline ->
                        Timeline.newFromEvents
                            { events = List.map (Event.initFromClientEventWithoutRoomId data.roomId) timeline.events
                            , nextBatch = data.nextBatch
                            , prevBatch = timeline.prevBatch
                            , stateDelta =
                                jroom.state
                                    |> Maybe.map
                                        (.events
                                            >> List.map (Event.initFromClientEventWithoutRoomId data.roomId)
                                            >> StateManager.fromEventList
                                        )
                            }
                    )
                |> Maybe.withDefault
                    (Timeline.newFromEvents
                        { events = []
                        , nextBatch = data.nextBatch
                        , prevBatch = Nothing
                        , stateDelta = Nothing
                        }
                    )
        }


{-| Adds an internal event to the `Room`. An internal event is a custom event
that has been generated by the client.
-}
addInternalEvent : IEvent.IEvent -> Room -> Room
addInternalEvent ievent (Room ({ room } as data)) =
    Room { data | room = Internal.addEvent ievent room }


{-| Adds an `Event` object to the `Room`. An `Event` is a value from the
`Internal.Event` module that is used to represent an event in a Matrix room.
-}
addEvent : Event -> Room -> Room
addEvent =
    Event.withoutCredentials >> addInternalEvent


{-| Creates a new `Room` object with the given parameters.
-}
withCredentials : Credentials -> Internal.IRoom -> Room
withCredentials context room =
    Room
        { context = context
        , room = room
        }


{-| Retrieves the `Internal.IRoom` type contained within the given `Room`.
-}
withoutCredentials : Room -> Internal.IRoom
withoutCredentials (Room { room }) =
    room


{-| Get the most recent events.
-}
mostRecentEvents : Room -> List Event
mostRecentEvents (Room { context, room }) =
    room
        |> Internal.mostRecentEvents
        |> List.map (Event.withCredentials context)


{-| Retrieves the ID of the Matrix room associated with the given `Room`.
-}
roomId : Room -> String
roomId =
    withoutCredentials >> Internal.roomId


{-| Sends a new event to the Matrix room associated with the given `Room`.
-}
sendEvent : Room -> { eventType : String, content : E.Value } -> Task X.Error VaultUpdate
sendEvent (Room { context, room }) { eventType, content } =
    Api.sendMessageEvent
        { content = content
        , eventType = eventType
        , extraTransactionNoise = "content-value:<object>"
        , roomId = Internal.roomId room
        }
        context


{-| Sends a new text message to the Matrix room associated with the given `Room`.
-}
sendMessage : Room -> String -> Task X.Error VaultUpdate
sendMessage (Room { context, room }) text =
    Api.sendMessageEvent
        { content =
            E.object
                [ ( "msgtype", E.string "m.text" )
                , ( "body", E.string text )
                ]
        , eventType = "m.room.message"
        , extraTransactionNoise = "literal-message:" ++ text
        , roomId = Internal.roomId room
        }
        context
