module RssPlugin exposing (generate)

import Head
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.Platform exposing (Builder)
import Pages.StaticHttp as StaticHttp
import Rss
import Time


generate :
    { siteTagline : String
    , siteUrl : String
    , title : String
    , builtAt : Time.Posix
    , indexPage : PagePath pathKey
    }
    ->
        ({ path : PagePath pathKey
         , frontmatter : metadata
         , body : String
         }
         -> Maybe Rss.Item
        )
    -> Builder pathKey userModel userMsg metadata view
    -> Builder pathKey userModel userMsg metadata view
generate options metadataToRssItem builder =
    let
        feedFilePath =
            (options.indexPage
                |> PagePath.toPath
            )
                ++ [ "feed.xml" ]
    in
    builder
        |> Pages.Platform.withFileGenerator
            (\siteMetadata ->
                { path = feedFilePath
                , content =
                    Rss.generate
                        { title = options.title
                        , description = options.siteTagline

                        -- TODO make sure you don't add an extra "/"
                        , url = options.siteUrl ++ "/" ++ PagePath.toString options.indexPage
                        , lastBuildTime = options.builtAt
                        , generator = Just "elm-pages"
                        , items = siteMetadata |> List.filterMap metadataToRssItem
                        , siteUrl = options.siteUrl
                        }
                }
                    |> Ok
                    |> List.singleton
                    |> StaticHttp.succeed
            )
        |> Pages.Platform.withGlobalHeadTags [ Head.rssLink (feedFilePath |> String.join "/") ]
