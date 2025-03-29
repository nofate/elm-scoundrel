module Types exposing (..)

type Suit
    = Clubs
    | Diamonds
    | Hearts
    | Spades

type Rank
    = Two
    | Three
    | Four
    | Five
    | Six
    | Seven
    | Eight
    | Nine
    | Ten
    | Jack
    | Queen
    | King
    | Ace

type CardType
    = Foe
    | Potion
    | Weapon

type alias Card =
    { suit : Suit
    , rank : Rank
    , cardType : CardType
    }

type alias Deck =
    List Card

type alias Room =
    { cards : List (Maybe Card)
    , number : Int
    }

type alias GameState =
    { deck : Deck
    , room : Room
    , weapon : Maybe Card
    , stackedFoes : List Card
    , discard : List Card
    , playerHealth : Int
    , canFlee : Bool
    , gameStatus : GameStatus
    , draggedCard : Maybe Card
    }

type GameStatus
    = Playing
    | Won
    | Lost

type Msg
    = DrawCards
    | EquipWeapon Card
    | UsePotion Card
    | FightBarehand Card
    | FightWithWeapon Card
    | DiscardWeapon
    | Flee
    | DragStart Card
    | DragEnd
    | DragOver String
    | Drop String
    | ShuffledDeck Deck
    | NoOp 