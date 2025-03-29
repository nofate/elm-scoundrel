module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, on, preventDefaultOn)
import Json.Decode as Decode
import Types exposing (..)
import Model exposing (getCardValue)

view : GameState -> Html Msg
view model =
    div [ class "game-container" ]
        [ viewHeader model
        , viewGameBoard model
        , viewGameStatus model
        ]

viewHeader : GameState -> Html Msg
viewHeader model =
    div [ class "header" ]
        [ h1 [] [ text "Scoundrel" ]
        , div [ class "health" ] 
            [ text ("Health: " ++ String.fromInt model.playerHealth ++ " / 20") ]
        , div [ class "room" ]
            [ text ("Room: " ++ String.fromInt model.room.number) ]
        ]

viewGameBoard : GameState -> Html Msg
viewGameBoard model =
    div [ class "game-board" ]
        [ div [ class "top-row" ]
            [ viewDeck model
            , viewWeaponSpot model
            , viewDiscardPile model
            ]
        , div [ class "room-row" ]
            [ viewRoom model ]
        , div [ class "controls" ]
            [ button 
                [ onClick Flee
                , disabled (not model.canFlee)
                ] 
                [ text "Flee" ]
            ]
        ]

viewDeck : GameState -> Html Msg
viewDeck model =
    div [ class "deck-container" ]
        [ div 
            [ class "deck"
            , onClick DrawCards
            ] 
            [ text ("Deck (" ++ String.fromInt (List.length model.deck) ++ ")")
            ]
        ]

viewWeaponSpot : GameState -> Html Msg
viewWeaponSpot model =
    div 
        [ class "weapon-spot"
        , attribute "data-target" "weapon"
        , onDragOver "weapon"
        , onDrop "weapon"
        ]
        [ case model.weapon of
            Nothing ->
                div [ class "empty-spot" ] [ text "Weapon" ]
                
            Just card ->
                div [ class "card-stack" ]
                    (viewCard card True :: viewStackedFoes model.stackedFoes)
        ]

viewDiscardPile : GameState -> Html Msg
viewDiscardPile model =
    div 
        [ class "discard-pile"
        , attribute "data-target" "discard"
        ]
        [ div [ class "discard" ]
            [ text ("Discard (" ++ String.fromInt (List.length model.discard) ++ ")")
            ]
        ]

viewRoom : GameState -> Html Msg
viewRoom model =
    div [ class "room-container" ]
        (model.room.cards
            |> List.indexedMap 
                (\i maybeCard -> 
                    div 
                        [ class "card-slot"
                        , attribute "data-index" (String.fromInt i)
                        ] 
                        [ case maybeCard of
                            Nothing ->
                                div [ class "empty-slot" ] []
                                
                            Just card ->
                                viewCard card False
                        ]
                )
        )

viewCard : Card -> Bool -> Html Msg
viewCard card isWeapon =
    let
        cardTypeClass =
            case card.cardType of
                Foe -> "foe"
                Potion -> "potion"
                Weapon -> "weapon"
                
        suitSymbol =
            case card.suit of
                Clubs -> "♣"
                Diamonds -> "♦"
                Hearts -> "♥"
                Spades -> "♠"
                
        rankText =
            case card.rank of
                Two -> "2"
                Three -> "3"
                Four -> "4"
                Five -> "5"
                Six -> "6"
                Seven -> "7"
                Eight -> "8"
                Nine -> "9"
                Ten -> "10"
                Jack -> "J"
                Queen -> "Q"
                King -> "K"
                Ace -> "A"
                
        cardValue = getCardValue card
        
        cardAction =
            if isWeapon then
                onClick DiscardWeapon
            else
                case card.cardType of
                    Potion -> onClick (UsePotion card)
                    Weapon -> onClick (EquipWeapon card)
                    Foe -> onClick (FightBarehand card)
    in
    div 
        [ class ("card " ++ cardTypeClass)
        , cardAction
        , draggable "true"
        , attribute "data-card-id" (toString card)
        , onDragStart DragStart card
        ] 
        [ div [ class "card-rank" ] [ text rankText ]
        , div [ class "card-suit" ] [ text suitSymbol ]
        , div [ class "card-value" ] [ text (String.fromInt cardValue) ]
        , div [ class "card-type" ] 
            [ text 
                (case card.cardType of
                    Foe -> "Foe"
                    Potion -> "Potion"
                    Weapon -> "Weapon"
                )
            ]
        ]

viewGameStatus : GameState -> Html Msg
viewGameStatus model =
    case model.gameStatus of
        Playing ->
            div [] []
            
        Won ->
            div [ class "game-over won" ]
                [ h2 [] [ text "Victory!" ]
                , p [] [ text "You defeated all the foes!" ]
                ]
                
        Lost ->
            div [ class "game-over lost" ]
                [ h2 [] [ text "Game Over" ]
                , p [] [ text "Your health reached zero!" ]
                ]

-- Helper for generating a string representation of a card
toString : Card -> String
toString card =
    let
        suitStr = 
            case card.suit of
                Clubs -> "C"
                Diamonds -> "D"
                Hearts -> "H" 
                Spades -> "S"
                
        rankStr =
            case card.rank of
                Two -> "2"
                Three -> "3"
                Four -> "4"
                Five -> "5"
                Six -> "6"
                Seven -> "7"
                Eight -> "8"
                Nine -> "9"
                Ten -> "10"
                Jack -> "J"
                Queen -> "Q"
                King -> "K"
                Ace -> "A"
    in
    rankStr ++ suitStr

-- Drag and drop event handlers
onDragStart : (Card -> Msg) -> Card -> Attribute Msg
onDragStart msgConstructor card =
    on "dragstart" (Decode.succeed (msgConstructor card))
        -- We're simplifying here: in a real implementation,
        -- you'd use dataTransfer.setData to store card info 

onDragOver : String -> Attribute Msg
onDragOver target =
    preventDefaultOn "dragover" (Decode.succeed (DragOver target, True))

onDrop : String -> Attribute Msg
onDrop target =
    preventDefaultOn "drop" (Decode.succeed (Drop target, True))

-- Function to view stacked foes with offset
viewStackedFoes : List Card -> List (Html Msg)
viewStackedFoes stackedFoes =
    List.indexedMap 
        (\index foe -> 
            div 
                [ class "stacked-foe"
                , style "left" (String.fromInt (index * 30) ++ "px")
                , style "top" (String.fromInt (index * 10) ++ "px")
                , style "z-index" (String.fromInt (10 + index))
                ] 
                [ viewCard foe False ]
        )
        stackedFoes 