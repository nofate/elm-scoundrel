module Main exposing (main)

import Browser
import Types exposing (..)
import Model exposing (init)
import Update exposing (update)
import View exposing (view)

main : Program () GameState Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        } 