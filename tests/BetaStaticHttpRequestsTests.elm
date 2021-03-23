module BetaStaticHttpRequestsTests exposing (all)

import Codec
import Dict
import Expect
import Html
import Json.Decode as JD
import Json.Encode as Encode
import OptimizedDecoder as Decode exposing (Decoder)
import Pages.ContentCache as ContentCache
import Pages.Document as Document
import Pages.ImagePath as ImagePath
import Pages.Internal.Platform.Cli as Main exposing (..)
import Pages.Internal.Platform.Effect as Effect exposing (Effect)
import Pages.Internal.Platform.ToJsPayload as ToJsPayload
import Pages.Internal.StaticHttpBody as StaticHttpBody
import Pages.Manifest as Manifest
import Pages.PagePath as PagePath
import Pages.StaticHttp as StaticHttp
import Pages.StaticHttp.Request as Request
import PagesHttp
import ProgramTest exposing (ProgramTest)
import Secrets
import SimulatedEffect.Cmd
import SimulatedEffect.Http as Http
import SimulatedEffect.Ports
import SimulatedEffect.Task
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Beta Static Http Requests"
        [ test "port is sent out once all requests are finished" <|
            \() ->
                start
                    [ ( [ "elm-pages" ]
                      , StaticHttp.get (Secrets.succeed "https://api.github.com/repos/dillonkearns/elm-pages") starDecoder
                      )
                    ]
                    |> ProgramTest.simulateHttpOk
                        "GET"
                        "https://api.github.com/repos/dillonkearns/elm-pages"
                        """{ "stargazer_count": 86 }"""
                    |> expectSuccess
                        [ ( "elm-pages"
                          , [ ( get "https://api.github.com/repos/dillonkearns/elm-pages"
                              , """{"stargazer_count":86}"""
                              )
                            ]
                          )
                        ]
        , test "two pages" <|
            \() ->
                start
                    [ ( [ "elm-pages" ]
                      , StaticHttp.get (Secrets.succeed "https://api.github.com/repos/dillonkearns/elm-pages") starDecoder
                      )
                    , ( [ "elm-pages-starter" ]
                      , StaticHttp.get (Secrets.succeed "https://api.github.com/repos/dillonkearns/elm-pages-starter") starDecoder
                      )
                    ]
                    |> ProgramTest.simulateHttpOk
                        "GET"
                        "https://api.github.com/repos/dillonkearns/elm-pages"
                        """{ "stargazer_count": 86 }"""
                    |> ProgramTest.simulateHttpOk
                        "GET"
                        "https://api.github.com/repos/dillonkearns/elm-pages-starter"
                        """{ "stargazer_count": 49 }"""
                    |> expectSuccess
                        [ ( "elm-pages"
                          , [ ( get "https://api.github.com/repos/dillonkearns/elm-pages"
                              , """{"stargazer_count":86}"""
                              )
                            ]
                          )
                        , ( "elm-pages-starter"
                          , [ ( get "https://api.github.com/repos/dillonkearns/elm-pages-starter"
                              , """{"stargazer_count":49}"""
                              )
                            ]
                          )
                        ]
        ]


start : List ( List String, StaticHttp.Request a ) -> ProgramTest (Main.Model PathKey ()) Main.Msg (Effect PathKey)
start pages =
    startWithHttpCache (Ok ()) [] pages


startWithHttpCache :
    Result String ()
    -> List ( Request.Request, String )
    -> List ( List String, StaticHttp.Request a )
    -> ProgramTest (Main.Model PathKey ()) Main.Msg (Effect PathKey)
startWithHttpCache =
    startLowLevel (StaticHttp.succeed [])


startLowLevel :
    StaticHttp.Request
        (List
            (Result String
                { path : List String
                , content : String
                }
            )
        )
    -> Result String ()
    -> List ( Request.Request, String )
    -> List ( List String, StaticHttp.Request a )
    -> ProgramTest (Main.Model PathKey ()) Main.Msg (Effect PathKey)
startLowLevel generateFiles documentBodyResult staticHttpCache pages =
    let
        document =
            Document.fromList
                [ Document.parser
                    { extension = "md"
                    , metadata = JD.succeed ()
                    , body = \_ -> documentBodyResult
                    }
                ]

        content =
            pages
                |> List.map
                    (\( path, _ ) ->
                        ( path, { extension = "md", frontMatter = "null", body = Just "" } )
                    )

        contentCache =
            ContentCache.init document content Nothing

        siteMetadata =
            contentCache
                |> Result.map
                    (\cache -> cache |> ContentCache.extractMetadata PathKey)
                |> Result.mapError (List.map Tuple.second)

        config =
            { toJsPort = toJsPort
            , fromJsPort = fromJsPort
            , manifest = manifest
            , generateFiles = \_ -> generateFiles
            , init = \_ -> ( (), Cmd.none )
            , update = \_ _ -> ( (), Cmd.none )
            , view =
                \allFrontmatter page ->
                    let
                        thing =
                            pages
                                |> Dict.fromList
                                |> Dict.get
                                    (page.path
                                        |> PagePath.toString
                                        |> String.split "/"
                                        |> List.filter (\pathPart -> pathPart /= "")
                                    )
                    in
                    case thing of
                        Just request ->
                            request
                                |> StaticHttp.map
                                    (\staticData -> { view = \model viewForPage -> { title = "Title", body = Html.text "" }, head = [] })

                        Nothing ->
                            Debug.todo "Couldn't find page"
            , subscriptions = \_ _ _ -> Sub.none
            , document = document
            , content =
                [ ( [ "elm-pages" ]
                  , { extension = "md", frontMatter = "{}", body = Nothing }
                  )
                ]
            , canonicalSiteUrl = canonicalSiteUrl
            , pathKey = PathKey
            , onPageChange = Just (\_ -> ())
            }

        encodedFlags =
            --{"secrets":
            --        {"API_KEY": "ABCD1234","BEARER": "XYZ789"}, "mode": "prod", "staticHttpCache": {}
            --        }
            Encode.object
                [ ( "secrets"
                  , [ ( "API_KEY", "ABCD1234" )
                    , ( "BEARER", "XYZ789" )
                    ]
                        |> Dict.fromList
                        |> Encode.dict identity Encode.string
                  )
                , ( "mode", Encode.string "elm-to-html-beta" )
                , ( "staticHttpCache", encodedStaticHttpCache )
                ]

        encodedStaticHttpCache =
            staticHttpCache
                |> List.map
                    (\( request, httpResponseString ) ->
                        ( Request.hash request, Encode.string httpResponseString )
                    )
                |> Encode.object
    in
    {-
       (Model -> model)
       -> ContentCache.ContentCache metadata view
       -> Result (List BuildError) (List ( PagePath pathKey, metadata ))
       -> Config pathKey userMsg userModel metadata view
       -> Decode.Value
       -> ( model, Effect pathKey )
    -}
    ProgramTest.createDocument
        { init = Main.init identity contentCache siteMetadata config
        , update = Main.update contentCache siteMetadata config
        , view = \_ -> { title = "", body = [] }
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start (flags (Encode.encode 0 encodedFlags))


canonicalSiteUrl =
    ""


flags : String -> JD.Value
flags jsonString =
    case JD.decodeString JD.value jsonString of
        Ok value ->
            value

        Err _ ->
            Debug.todo "Invalid JSON value."


simulateEffects : Effect PathKey -> ProgramTest.SimulatedEffect Main.Msg
simulateEffects effect =
    case effect of
        Effect.NoEffect ->
            SimulatedEffect.Cmd.none

        Effect.SendJsData value ->
            SimulatedEffect.Ports.send "toJsPort" (value |> Codec.encoder (ToJsPayload.toJsCodec canonicalSiteUrl))

        --            toJsPort value |> Cmd.map never
        Effect.Batch list ->
            list
                |> List.map simulateEffects
                |> SimulatedEffect.Cmd.batch

        Effect.FetchHttp ({ unmasked, masked } as requests) ->
            Http.request
                { method = unmasked.method
                , url = unmasked.url
                , headers = unmasked.headers |> List.map (\( key, value ) -> Http.header key value)
                , body =
                    case unmasked.body of
                        StaticHttpBody.EmptyBody ->
                            Http.emptyBody

                        StaticHttpBody.StringBody contentType string ->
                            Http.stringBody contentType string

                        StaticHttpBody.JsonBody value ->
                            Http.jsonBody value
                , expect =
                    PagesHttp.expectString
                        (\response ->
                            GotStaticHttpResponse
                                { request = requests
                                , response = response
                                }
                        )
                , timeout = Nothing
                , tracker = Nothing
                }

        Effect.SendSinglePage info ->
            SimulatedEffect.Cmd.batch
                [ info
                    |> Codec.encoder (ToJsPayload.successCodecNew2 "" "")
                    |> SimulatedEffect.Ports.send "toJsPort"
                , SimulatedEffect.Task.succeed ()
                    |> SimulatedEffect.Task.perform (\_ -> Main.Continue)
                ]

        Effect.Continue ->
            SimulatedEffect.Cmd.none



--SimulatedEffect.Task.succeed ()
--    |> SimulatedEffect.Task.perform (\_ -> Main.Continue)


toJsPort foo =
    Cmd.none


fromJsPort =
    Sub.none


type PathKey
    = PathKey


manifest : Manifest.Config PathKey
manifest =
    { backgroundColor = Nothing
    , categories = []
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = "elm-pages - A statically typed site generator."
    , iarcRatingId = Nothing
    , name = "elm-pages docs"
    , themeColor = Nothing
    , startUrl = PagePath.external ""
    , shortName = Just "elm-pages"
    , sourceIcon = ImagePath.external ""
    , icons = []
    }


starDecoder : Decoder Int
starDecoder =
    Decode.field "stargazer_count" Decode.int


expectSuccess : List ( String, List ( Request.Request, String ) ) -> ProgramTest model msg effect -> Expect.Expectation
expectSuccess expectedRequests previous =
    previous
        |> ProgramTest.expectOutgoingPortValues
            "toJsPort"
            (Codec.decoder (ToJsPayload.successCodecNew2 "" ""))
            (\portPayloads ->
                portPayloads
                    |> List.filterMap
                        (\portPayload ->
                            case portPayload of
                                ToJsPayload.PageProgress value ->
                                    Just ( value.route, value.contentJson )

                                ToJsPayload.InitialData record ->
                                    Nothing
                        )
                    |> Dict.fromList
                    |> Expect.equalDicts
                        (expectedRequests
                            |> List.map
                                (\( url, requests ) ->
                                    ( url
                                    , requests
                                        |> List.map
                                            (\( request, response ) ->
                                                ( Request.hash request, response )
                                            )
                                        |> Dict.fromList
                                    )
                                )
                            |> Dict.fromList
                        )
            )


get : String -> Request.Request
get url =
    { method = "GET"
    , url = url
    , headers = []
    , body = StaticHttp.emptyBody
    }
