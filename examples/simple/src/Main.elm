port module Main exposing (main)

import Color
import Element exposing (Element)
import Element.Font as Font
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes
import MarkdownRenderer
import Metadata exposing (Metadata)
import MimeType
import OptimizedDecoder as D
import Pages exposing (images, pages)
import Pages.ImagePath as ImagePath exposing (ImagePath)
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath exposing (PagePath)
import Pages.Platform exposing (Page)
import Pages.StaticHttp as StaticHttp
import Secrets
import Time


port example : String -> Cmd msg


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Just Color.white
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = "elm-pages - A statically typed site generator."
    , iarcRatingId = Nothing
    , name = "elm-pages docs"
    , themeColor = Just Color.white
    , startUrl = pages.index
    , shortName = Just "elm-pages"
    , sourceIcon = images.iconPng
    , icons =
        [ icon webp 192
        , icon webp 512
        , icon MimeType.Png 192
        , icon MimeType.Png 512
        ]
    }


webp : MimeType.MimeImage
webp =
    MimeType.OtherImage "webp"


icon :
    MimeType.MimeImage
    -> Int
    -> Manifest.Icon pathKey
icon format width =
    { src = cloudinaryIcon format width
    , sizes = [ ( width, width ) ]
    , mimeType = format |> Just
    , purposes = []
    }


cloudinaryIcon :
    MimeType.MimeImage
    -> Int
    -> ImagePath pathKey
cloudinaryIcon format width =
    let
        base =
            "https://res.cloudinary.com/dillonkearns/image/upload"

        asset =
            "v1603234028/elm-pages/elm-pages-icon"

        fetch_format =
            case format of
                MimeType.Png ->
                    "png"

                MimeType.OtherImage "webp" ->
                    "webp"

                _ ->
                    "auto"

        transforms =
            [ "c_pad"
            , "w_" ++ String.fromInt width
            , "h_" ++ String.fromInt width
            , "q_auto"
            , "f_" ++ fetch_format
            ]
                |> String.join ","
    in
    ImagePath.external (base ++ "/" ++ transforms ++ "/" ++ asset)


type alias View =
    ( MarkdownRenderer.TableOfContents, List (Element Msg) )


main : Pages.Platform.Program Model Msg Metadata View Pages.PathKey
main =
    Pages.Platform.init
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , documents =
            [ { extension = "md"
              , metadata = Metadata.decoder
              , body = MarkdownRenderer.view
              }
            ]
        , onPageChange = Nothing
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        , internals = Pages.internals
        }
        |> Pages.Platform.withFileGenerator fileGenerator
        |> Pages.Platform.withGlobalHeadTags
            [ Head.icon [ ( 32, 32 ) ] MimeType.Png (cloudinaryIcon MimeType.Png 32)
            , Head.icon [ ( 16, 16 ) ] MimeType.Png (cloudinaryIcon MimeType.Png 16)
            , Head.appleTouchIcon (Just 180) (cloudinaryIcon MimeType.Png 180)
            , Head.appleTouchIcon (Just 192) (cloudinaryIcon MimeType.Png 192)
            ]
        |> Pages.Platform.toProgram


fileGenerator :
    List { path : PagePath Pages.PathKey, frontmatter : metadata, body : String }
    ->
        StaticHttp.Request
            (List
                (Result String
                    { path : List String
                    , content : String
                    }
                )
            )
fileGenerator siteMetadata =
    StaticHttp.succeed
        [ Ok { path = [ "hello.txt" ], content = "Hello there!" }
        , Ok { path = [ "goodbye.txt" ], content = "Goodbye there!" }
        ]


type alias Model =
    { showMobileMenu : Bool
    , counter : Int
    }


init :
    Maybe
        { path :
            { path : PagePath Pages.PathKey
            , query : Maybe String
            , fragment : Maybe String
            }
        , metadata : Metadata
        }
    -> ( Model, Cmd Msg )
init maybePagePath =
    ( Model False 0, example "Whyyyyy hello there!" )


type Msg
    = OnPageChange
        { path : PagePath Pages.PathKey
        , query : Maybe String
        , fragment : Maybe String
        }
    | ToggleMobileMenu
    | Tick


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange page ->
            ( { model | showMobileMenu = False }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | showMobileMenu = not model.showMobileMenu }, Cmd.none )

        Tick ->
            ( { model | counter = model.counter + 1 }, Cmd.none )


subscriptions : Metadata -> PagePath Pages.PathKey -> Model -> Sub Msg
subscriptions _ _ _ =
    Time.every 1000 (\_ -> Tick)


view :
    List ( PagePath Pages.PathKey, Metadata )
    ->
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        }
    ->
        StaticHttp.Request
            { view : Model -> View -> { title : String, body : Html Msg }
            , head : List (Head.Tag Pages.PathKey)
            }
view siteMetadata page =
    case page.frontmatter of
        Metadata.Page meta ->
            StaticHttp.get
                (Secrets.succeed <| "https://api.github.com/repos/dillonkearns/" ++ meta.repo)
                (D.field "stargazers_count" D.int)
                |> StaticHttp.map
                    (\stars ->
                        { view =
                            \model _ ->
                                { title = "Title"
                                , body =
                                    Html.div []
                                        [ Html.h1 [] [ Html.text meta.repo ]
                                        , Html.div []
                                            [ Html.text <| "GitHub Stars: " ++ String.fromInt stars ]
                                        , Html.div []
                                            [ Html.text <| "Counter: " ++ String.fromInt model.counter ]
                                        , Html.div []
                                            [ Html.a [ Html.Attributes.href "/" ] [ Html.text "elm-pages" ]
                                            , Html.a [ Html.Attributes.href "/elm-markdown" ] [ Html.text "elm-markdown" ]
                                            ]
                                        ]
                                }
                        , head = head page.path page.frontmatter
                        }
                    )


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : PagePath Pages.PathKey -> Metadata -> List (Head.Tag Pages.PathKey)
head currentPath metadata =
    case metadata of
        Metadata.Page meta ->
            Seo.summary
                { canonicalUrlOverride = Nothing
                , siteName = "elm-pages"
                , image =
                    { url = images.iconPng
                    , alt = "elm-pages logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = meta.title
                }
                |> Seo.website


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://elm-pages.com"


siteTagline : String
siteTagline =
    "A statically typed site generator - elm-pages"


tocView : MarkdownRenderer.TableOfContents -> Element msg
tocView toc =
    Element.column [ Element.alignTop, Element.spacing 20 ]
        [ Element.el [ Font.bold, Font.size 22 ] (Element.text "Table of Contents")
        , Element.column [ Element.spacing 10 ]
            (toc
                |> List.map
                    (\heading ->
                        Element.link [ Font.color (Element.rgb255 100 100 100) ]
                            { url = "#" ++ heading.anchorId
                            , label = Element.text heading.name
                            }
                    )
            )
        ]
