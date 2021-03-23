module Template.Documentation exposing (Model, Msg, decoder, template)

import DocSidebar
import Element exposing (Element)
import Element.Events
import Element.Font as Font
import Element.Region
import Head
import Head.Seo as Seo
import Json.Decode as Decode
import MarkdownRenderer
import Pages exposing (images)
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.StaticHttp as StaticHttp
import Palette
import Shared
import Site
import Template exposing (StaticPayload, TemplateWithState)
import TemplateMetadata exposing (Documentation)
import TemplateType exposing (TemplateType)


type alias StaticData =
    ()


type alias Model =
    {}


type Msg
    = Increment


template : TemplateWithState Documentation StaticData Model Msg
template =
    Template.noStaticData { head = head }
        |> Template.buildWithSharedState
            { view = view
            , init = init
            , update = update
            , subscriptions = \_ _ _ _ -> Sub.none
            }


init : Documentation -> ( Model, Cmd Msg )
init metadata =
    ( {}, Cmd.none )


update : Documentation -> Msg -> Model -> Shared.Model -> ( Model, Cmd Msg, Maybe Shared.SharedMsg )
update metadata msg model sharedModel =
    case msg of
        Increment ->
            ( model, Cmd.none, Just Shared.IncrementFromChild )


staticData :
    List ( PagePath Pages.PathKey, TemplateType )
    -> StaticHttp.Request StaticData
staticData siteMetadata =
    StaticHttp.succeed ()


decoder : Decode.Decoder Documentation
decoder =
    Decode.map Documentation
        (Decode.field "title" Decode.string)


head : StaticPayload Documentation StaticData -> List (Head.Tag Pages.PathKey)
head staticPayload =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = images.iconPng
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = Site.tagline
        , locale = Nothing
        , title = staticPayload.metadata.title
        }
        |> Seo.website


view :
    Model
    -> Shared.Model
    -> List ( PagePath Pages.PathKey, TemplateType )
    -> StaticPayload Documentation StaticData
    -> Shared.RenderedBody
    -> Shared.PageView Msg
view model sharedModel allMetadata staticPayload rendered =
    { title = staticPayload.metadata.title
    , body =
        [ [ Element.row []
                [ --counterView sharedModel,
                  DocSidebar.view
                    staticPayload.path
                    allMetadata
                    |> Element.el [ Element.width (Element.fillPortion 2), Element.alignTop, Element.height Element.fill ]
                , Element.column [ Element.width (Element.fillPortion 8), Element.padding 35, Element.spacing 15 ]
                    [ Palette.heading 1 [ Element.text staticPayload.metadata.title ]
                    , Element.column [ Element.spacing 20 ]
                        [ tocView staticPayload.path (Tuple.first rendered)
                        , Element.column
                            [ Element.padding 50
                            , Element.spacing 30
                            , Element.Region.mainContent
                            ]
                            (Tuple.second rendered |> List.map (Element.map never))
                        ]
                    ]
                ]
          ]
            |> Element.textColumn
                [ Element.width Element.fill
                , Element.height Element.fill
                ]
        ]
    }


counterView : Shared.Model -> Element Msg
counterView sharedModel =
    Element.el [ Element.Events.onClick Increment ] (Element.text <| "Docs count: " ++ String.fromInt sharedModel.counter)


tocView : PagePath Pages.PathKey -> MarkdownRenderer.TableOfContents -> Element msg
tocView path toc =
    Element.column [ Element.alignTop, Element.spacing 20 ]
        [ Element.el [ Font.bold, Font.size 22 ] (Element.text "Table of Contents")
        , Element.column [ Element.spacing 10 ]
            (toc
                |> List.map
                    (\heading ->
                        Element.link [ Font.color (Element.rgb255 100 100 100) ]
                            { url = PagePath.toString path ++ "#" ++ heading.anchorId
                            , label = Element.text heading.name
                            }
                    )
            )
        ]
