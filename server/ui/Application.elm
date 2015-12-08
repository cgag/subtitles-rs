module Application (Model, Action, init, update, view) where

import Effects exposing (Never)
import Html exposing (div, text)

import Video
import Util exposing (listFromMaybe, updateChild)

type alias Model =
  { errorMessage: Maybe String
  , video: Maybe Video.Model
  }

type Action
  = VideoLoaded (Maybe (Video.Model, Effects.Effects Video.Action))
  | VideoAction Video.Action

init : (Model, Effects.Effects Action)
init = (Model Nothing Nothing, Video.load VideoLoaded)

update : Action -> Model -> (Model, Effects.Effects Action)
update msg model =
  case msg of
    VideoLoaded Nothing ->
      let
        model' = { model | errorMessage = Just "Could not load video" }
      in (model', Effects.none)

    VideoLoaded (Just (video, fx)) ->
      ({ model | video = Just video }, Effects.map VideoAction fx)

    VideoAction act ->
      case model.video of
        Just video ->
          updateChild act video Video.update VideoAction
            (\v -> { model | video = Just v })
        Nothing ->
          (model, Effects.none)

view : Signal.Address Action -> Model -> Html.Html
view address model =
  let
    flash =
      Maybe.map (\err -> text err) model.errorMessage
    videoAddr = Signal.forwardTo address VideoAction
    player =
      Maybe.map (\video -> Video.playerView videoAddr video) model.video
    subtitles =
      Maybe.map (\video -> Video.subtitlesView videoAddr video) model.video
    children =
      listFromMaybe flash ++ listFromMaybe player ++ listFromMaybe subtitles
  in div [] children