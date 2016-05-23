module Home exposing (main)

import Json.Decode as Json
import Html exposing (Html, div, text, a, hr)
import Html.App as Html
import Html.Attributes exposing (class, href, target)
import Html.Events exposing (on)
import Svg exposing (svg, line, linearGradient, stop)
import Svg.Attributes exposing (x1, x2, y1, y2, stroke, height, width, offset, id, style)
import List
import Window
import Mouse exposing (Position)
import Task exposing (perform)
import Random exposing (float, int, map3)

main =
  Html.program {init = init, view = view, update = update, subscriptions = subscriptions}


-- MODEL

type alias MeteorInit = {
  x: Int
  , y: Int
  , end: Int
}

type alias Meteor = {
  x: Int
  , y: Int
  , current: Int
  , end: Int
}

type alias Model = {
  meteors: List Meteor
  , windowWidth: Int
  , windowHeight: Int
  , mouseX: Int
  , mouseY: Int
}

init : (Model, Cmd Msg)
init =
  ({
  meteors = []
  , windowWidth = 0
  , windowHeight = 0
  , mouseX = 0
  , mouseY = 0
  }
  , perform Resize Resize Window.size)

-- UPDATE
type Msg
  = Wheel
  | Prob Float
  | Add MeteorInit
  | Resize Window.Size
  | Move Position

lineOffset meteor height =
  height - meteor.y - meteor.x

tailLength =
  85 

progress current end =
  if current < end then
    current + 6
  else
    current + 2


progressMeteors : List Meteor -> List Meteor
progressMeteors model =
  List.map (\m -> {m | current = progress m.current m.end}) model
    |> List.filter (\m -> m.current < m.end + tailLength)

minLength = 240
maxLength = 450

newMeteor: Int -> Int -> Cmd Msg
newMeteor windowWidth windowHeight=
    map3 (\x y end -> MeteorInit x y end) (int maxLength windowWidth) (int 1 (windowHeight - maxLength)) (int minLength maxLength)
      |> Random.generate Add

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    maxMeteors = 10
  in
    case msg of
      Wheel ->
        ({model | meteors = progressMeteors model.meteors}, Random.generate Prob (float 0 1))
      Prob p ->
        if p < (((toFloat (maxMeteors - (List.length model.meteors))) / (toFloat maxMeteors)) ^ 2) then
          (model, newMeteor model.windowWidth model.windowHeight)
        else
          (model, Cmd.none)
      Add mi ->
        let
          shouldAdd = List.all (\m -> abs ((lineOffset m model.windowHeight) - (lineOffset mi model.windowHeight)) > 70)  model.meteors
        in
          if shouldAdd then
            ({model | meteors = model.meteors ++ [(Meteor mi.x mi.y 0 mi.end)]}, Cmd.none)
          else
            (model, Cmd.none)
      Resize size ->
        ({model
          | windowWidth = size.width
          , windowHeight = size.height
        }, Cmd.none)
      Move pos ->
        ({model
          | mouseX = pos.x
          , mouseY = pos.y
        }, Cmd.none)


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [Window.resizes Resize, Mouse.moves Move]

-- VIEW

onWheel : msg -> Html.Attribute msg
onWheel message =
  on "wheel" (Json.succeed message)

stopPoint current end =
  if current >= end then
    toString (tailLength - (current - end))
  else
    toString tailLength

perspectiveOffset : Int -> Int -> Int -> Int -> String
perspectiveOffset mouseX mouseY windowWidth windowHeight =
  let
    maxOffset = 40
  in
    "top:"
    ++ (toString (((((toFloat windowHeight) / 2.0) - (toFloat mouseY)) / (toFloat windowHeight)) * maxOffset))
    ++ "px;"
    ++ "left:"
    ++ (toString (((((toFloat windowWidth) / 2.0) - (toFloat mouseX)) / (toFloat windowWidth)) * maxOffset))
    ++ "px;"



view : Model -> Html.Html Msg
view model =
  div [class "Elm-Home", onWheel Wheel] [
    svg [width "100%", height "100%", style ("position: absolute;" ++ (perspectiveOffset model.mouseX model.mouseY model.windowWidth model.windowHeight))] (
      (List.indexedMap (\i m -> linearGradient [
        id ("gradient" ++ (toString i)), x1 "0%", y1 "0%", x2 "100%", y2 "0%"
      ] [
        stop [offset "0%", style "stop-color: rgb(255, 255, 255); stop-opacity: 1"] []
        , stop [offset ((stopPoint m.current m.end) ++ "%"), style "stop-color: rgb(255, 255, 255); stop-opacity:0"] []
      ]) model.meteors)
      ++ (List.indexedMap (\i m -> (line [
        x1 (toString m.x)
        , y1 (toString m.y)
        , x2 (toString (m.x - (min m.current m.end)))
        , y2 (toString (m.y + (min m.current m.end)))
        , stroke ("url(#gradient" ++ (toString i) ++ ")")
      ] [])) model.meteors)
    )
    , div [class "text"] [
      div [class "name"] [text "Albert Lo"]
      , div [class "primary"] [
        a [href "https://xkcd.com/844/", target "_blank"] [text "software engineer"]
        , text " / "
        , a [href "https://xkcd.com/1678/", target "_blank"] [text "generalist"]
      ]
      , div [class "secondary"] [
        a [href "https://xkcd.com/1537/", target "_blank"] [text "js ethuiast"]
        , text " / "
        , a [href "https://xkcd.com/1270/", target "_blank"] [text "lambda fanatic"]
      ]
      , hr [] []
      , div [class "links"] [
        a [href "https://github.com/BertLo", target "_blank"] [text "github"]
        , text " / "
        , a [href "https://www.linkedin.com/in/alberthtlo", target "_blank"] [text "linkedin"]
        , text " / "
        , a [href "/resume", target "_blank"] [text "resume"]
      ]
    ]
  ]
