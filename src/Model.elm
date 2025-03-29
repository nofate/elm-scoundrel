module Model exposing (..)

import Types exposing (..)
import Deck exposing (createDeck, shuffle)

init : () -> ( GameState, Cmd Msg )
init _ =
    ( initialGameState
    , shuffle initialGameState.deck
    )

initialGameState : GameState
initialGameState =
    { deck = createDeck
    , room = { cards = [Nothing, Nothing, Nothing, Nothing], number = 0 }
    , weapon = Nothing
    , stackedFoes = []
    , discard = []
    , playerHealth = 20
    , canFlee = True
    , gameStatus = Playing
    , draggedCard = Nothing
    }

rankToValue : Rank -> Int
rankToValue rank =
    case rank of
        Two -> 2
        Three -> 3
        Four -> 4
        Five -> 5
        Six -> 6
        Seven -> 7
        Eight -> 8
        Nine -> 9
        Ten -> 10
        Jack -> 11
        Queen -> 12
        King -> 13
        Ace -> 14

getCardValue : Card -> Int
getCardValue card =
    rankToValue card.rank 