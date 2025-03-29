module Deck exposing (..)

import Types exposing (..)
import Random
import Random.List

createDeck : Deck
createDeck =
    let
        ranks = 
            [ Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace ]
            
        suits = 
            [ Clubs, Diamonds, Hearts, Spades ]
            
        allCards =
            List.concatMap 
                (\suit -> 
                    List.map 
                        (\rank -> 
                            { suit = suit
                            , rank = rank
                            , cardType = getCardType suit rank
                            }
                        ) 
                        ranks
                ) 
                suits
    in
    -- Remove red face cards (Hearts and Diamonds Jack, Queen, King) and red aces
    List.filter 
        (\card -> 
            not ((card.suit == Hearts || card.suit == Diamonds) && 
                (card.rank == Jack || card.rank == Queen || card.rank == King || card.rank == Ace))
        )
        allCards

getCardType : Suit -> Rank -> CardType
getCardType suit _ =
    case suit of
        Clubs -> Foe
        Spades -> Foe
        Hearts -> Potion
        Diamonds -> Weapon

shuffle : Deck -> Cmd Msg
shuffle deck =
    Random.generate ShuffledDeck (Random.List.shuffle deck) 