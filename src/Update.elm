module Update exposing (update)

import Types exposing (..)
import Model exposing (getCardValue, rankToValue)
import Random
import Random.List
import List.Extra exposing (getAt, setAt, removeAt)

update : Msg -> GameState -> ( GameState, Cmd Msg )
update msg model =
    case msg of
        DrawCards ->
            drawCardsToRoom model

        ShuffledDeck newDeck ->
            ( { model | deck = newDeck }
            , Cmd.none
            )

        EquipWeapon card ->
            ( equipWeapon card model
            , Cmd.none
            )

        UsePotion card ->
            ( usePotion card model
            , Cmd.none
            )

        FightBarehand card ->
            ( fightBarehand card model
            , Cmd.none
            )

        FightWithWeapon card ->
            ( fightWithWeapon card model
            , Cmd.none
            )

        DiscardWeapon ->
            ( discardWeapon model
            , Cmd.none
            )

        Flee ->
            fleeRoom model

        DragStart card ->
            ( { model | draggedCard = Just card }, Cmd.none )

        DragEnd ->
            ( { model | draggedCard = Nothing }, Cmd.none )

        DragOver _ ->
            ( model, Cmd.none )

        Drop target ->
            case model.draggedCard of
                Nothing -> 
                    ( model, Cmd.none )
                
                Just card ->
                    if target == "weapon" && card.cardType == Foe && model.weapon /= Nothing then
                        ( fightWithWeapon card model, Cmd.none )
                    else
                        ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

-- Draw cards from the deck to fill the room
drawCardsToRoom : GameState -> ( GameState, Cmd Msg )
drawCardsToRoom model =
    let
        -- Count how many cards are currently in the room
        cardsInRoom =
            model.room.cards
                |> List.filterMap identity
                |> List.length
                
        -- Only allow drawing if 0 or 1 cards remain
        canDraw = cardsInRoom <= 1
    in
    if not canDraw then
        -- If we can't draw, just return the model unchanged
        ( model, Cmd.none )
    else
        let
            emptySpots =
                model.room.cards
                    |> List.indexedMap Tuple.pair
                    |> List.filter (\(_, card) -> card == Nothing)
                    |> List.map Tuple.first
            
            cardsToDraw =
                min (List.length emptySpots) (List.length model.deck)
                
            (drawnCards, remainingDeck) =
                List.Extra.splitAt cardsToDraw model.deck
                
            newRoom =
                List.foldl
                    (\(index, card) room ->
                        { room | cards = setAt index (Just card) room.cards }
                    )
                    { cards = model.room.cards, number = model.room.number + 1 }
                    (List.map2 Tuple.pair emptySpots drawnCards)
                    
            newGameState =
                { model
                | deck = remainingDeck
                , room = newRoom
                , canFlee = True  -- Reset the canFlee flag when entering a new room
                }
                |> checkGameStatus
        in
        ( newGameState, Cmd.none )

-- Equip a weapon card
equipWeapon : Card -> GameState -> GameState
equipWeapon card model =
    let
        newRoom =
            { cards = 
                model.room.cards
                    |> List.map (\c -> if c == Just card then Nothing else c)
            , number = model.room.number
            }
            
        newGameState =
            case model.weapon of
                Nothing ->
                    { model
                    | room = newRoom
                    , weapon = Just card
                    }
                    
                Just oldWeapon ->
                    { model
                    | room = newRoom
                    , weapon = Just card
                    , discard = oldWeapon :: model.discard
                    }
    in
    checkGameStatus newGameState

-- Use a potion card
usePotion : Card -> GameState -> GameState
usePotion card model =
    let
        healAmount = getCardValue card
        
        newHealth = min 20 (model.playerHealth + healAmount)
        
        newRoom =
            { cards = 
                model.room.cards
                    |> List.map (\c -> if c == Just card then Nothing else c)
            , number = model.room.number
            }
    in
    checkGameStatus
        { model
        | playerHealth = newHealth
        , room = newRoom
        , discard = card :: model.discard
        }

-- Fight with bare hands
fightBarehand : Card -> GameState -> GameState
fightBarehand card model =
    let
        damage = getCardValue card
        
        newHealth = model.playerHealth - damage
        
        newRoom =
            { cards = 
                model.room.cards
                    |> List.map (\c -> if c == Just card then Nothing else c)
            , number = model.room.number
            }
            
        newGameState =
            { model
            | playerHealth = newHealth
            , room = newRoom
            , discard = card :: model.discard
            }
    in
    checkGameStatus newGameState

-- Fight with weapon
fightWithWeapon : Card -> GameState -> GameState
fightWithWeapon foe model =
    case model.weapon of
        Nothing ->
            -- If no weapon, treat as barehand
            fightBarehand foe model
            
        Just weapon ->
            -- Check if this foe's rank is lower than the current weapon's "limit"
            -- This is how we implement the "only fight foes of lower rank" rule
            let
                lastDefeatedFoeRank = 
                    if List.isEmpty model.stackedFoes then
                        -- No foes defeated yet, any foe can be fought
                        Nothing
                    else
                        -- Get the rank of the last defeated foe
                        model.stackedFoes
                            |> List.head
                            |> Maybe.map .rank
                        
                canFight = 
                    case lastDefeatedFoeRank of
                        Nothing -> 
                            -- Fresh weapon, can fight any foe
                            True
                        Just lastRank ->
                            -- Can only fight foes of lower rank
                            rankToValue foe.rank < rankToValue lastRank
                        
                foeValue = getCardValue foe
                weaponValue = getCardValue weapon
                
                damage = max 0 (foeValue - weaponValue)
                
                newHealth = model.playerHealth - damage
                
                newRoom =
                    { cards = 
                        model.room.cards
                            |> List.map (\c -> if c == Just foe then Nothing else c)
                    , number = model.room.number
                    }
                    
                newGameState =
                    if canFight then
                        { model
                        | playerHealth = newHealth
                        , room = newRoom
                        , stackedFoes = model.stackedFoes ++ [foe]
                        , draggedCard = Nothing
                        }
                    else
                        -- Can't fight this foe with this weapon
                        model
            in
            checkGameStatus newGameState

-- Discard weapon
discardWeapon : GameState -> GameState
discardWeapon model =
    case model.weapon of
        Nothing ->
            model
            
        Just weapon ->
            checkGameStatus
                { model
                | weapon = Nothing
                , stackedFoes = []  -- Clear stacked foes
                , discard = weapon :: (model.stackedFoes ++ model.discard)  -- Add weapon and all stacked foes to discard
                }

-- Flee from the room
fleeRoom : GameState -> ( GameState, Cmd Msg )
fleeRoom model =
    let
        -- Get cards currently in the room
        roomCards =
            model.room.cards
                |> List.filterMap identity
                
        -- Check if room is empty
        isRoomEmpty = List.isEmpty roomCards
    in
    if not model.canFlee || isRoomEmpty then
        -- Can't flee if already fled last room or the room is empty
        ( model, Cmd.none )
    else
        let
            newRoom =
                { cards = List.repeat 4 Nothing
                , number = model.room.number
                }
        in
        ( { model
          | room = newRoom
          , canFlee = False
          }
        , Random.generate ShuffledDeck (Random.List.shuffle (model.deck ++ roomCards))
        )

-- Check if the game is won or lost
checkGameStatus : GameState -> GameState
checkGameStatus model =
    if model.playerHealth <= 0 then
        { model | gameStatus = Lost }
    else
        let
            -- Count foes in deck and room
            foesInDeck =
                List.filter (\card -> card.cardType == Foe) model.deck
                
            foesInRoom =
                model.room.cards
                    |> List.filterMap identity
                    |> List.filter (\card -> card.cardType == Foe)
        in
        if List.isEmpty foesInDeck && List.isEmpty foesInRoom then
            { model | gameStatus = Won }
        else
            model 