# Changelog [![Elm package](https://img.shields.io/elm-package/v/dillonkearns/elm-pages.svg)](https://package.elm-lang.org/packages/dillonkearns/elm-pages/latest/)

All notable changes to
[the `dillonkearns/elm-pages` elm package](http://package.elm-lang.org/packages/dillonkearns/elm-pages/latest)
will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [7.0.0] - 2020-10-26

See the upgrade guide for some information for getting to the latest version, and how to try out the 2 new opt-in beta features: https://github.com/dillonkearns/elm-pages/blob/master/docs/7.0.0-elm-package-upgrade-guide.md.

### Fixed

- Fixed a bug where using `ImagePath.external` in any `Head` tags would prepend the canonical site URL to the external URL, creating an invalid URL. Now it will only prepend the canonical site URL for local images, and it will use external image URLs directly with no modifications.
- StaticHttp performance improvements - whether you use the new beta build or the existing `elm-pages build` or `elm-pages develop` commands, you should see significantly faster StaticHttp any place you combined multiple StaticHttp results together. I would welcome getting any before/after performance numbers!

### Changed

- There is now an `icons` field in the `Manifest.Config` type. You can use an empty List if you are not using the beta no-webpack build (it will be ignored if you use `elm-pages build`, but will be used going forward with the beta which will eventually replace `elm-pages build`).

### Added

- There are 2 new beta features, a new beta no-webpack build and a beta Template Modules feature (see https://github.com/dillonkearns/elm-pages/blob/master/docs/7.0.0-elm-package-upgrade-guide.md for detailed info and instructions).

## [6.0.0] - 2020-07-14

### Fixed

- Fixed missing content message flash for pages that are hosted on a sub path: https://github.com/dillonkearns/elm-pages/issues/106.

## [5.0.2] - 2020-06-16

### Fixed

- Fixed issue where CLI would hang when fetching StaticHttp data for `generateFiles` functions. The problem was a looping condition for completing the CLI process to fetch StaticHttp data.
  See [#120](https://github.com/dillonkearns/elm-pages/pull/120).

## [5.0.1] - 2020-05-13

### Fixed

- Make sure the build fails when there are `Err` results in any markdown content. Fixes [#102](https://github.com/dillonkearns/elm-pages/issues/102).
  This fix also means that any markdown errors will cause the error overlay in the dev server to show.

## [5.0.0] - 2020-05-11

### Changed

- Use builder pattern to build application. In place of the old `Pages.Platform.application`, you now start building an application config with `Pages.Platform.init`, and complete it with `Pages.Platform.toProgram`. You can chain on some calls to your application builder. This is handy for creating plugins that generate some files and add some head tags using `withGlobalHeadTags`.
- The `documents` key is now a List of records. The `Pages.Document` module has been removed entirely in place of a simplified API. `elm-markup` files no longer have any special handling
  and the direct dependency was removed from `elm-pages`. Instead, to use `elm-markup` with `elm-pages`, you now wire it in as you would with a markdown parser or any other document handler.
- Replaced `generateFiles` field in `Pages.Platform.application` with the `Pages.Platform.withFileGenerator` function.
- Instead of using the `zwilias/json-decode-exploration` package directly to build up optimizable decoders, you now use the `OptimizedDecoder` API. It provides the same drop-in replacement,
  with the same underlying package. But it now uses a major optimization where in your production build, it will run a plain `elm/json` decoder
  (on the optimized JSON asset that was produced in the build step) to improve performance.

### Added

- Added `Head.Seo.structuredData`. Check out Google's [structured data gallery](https://developers.google.com/search/docs/guides/search-gallery) to see some examples of what structured
  data looks like in rich search results that it provides. Right now, the API takes a simple `Json.Encode.Value`. In the `elm-pages` repo, I have an example API that I use,
  but it's not public yet because I want to refine the API before releasing it (and it's a large undertaking!). But for now, you can add whatever structured data you need,
  you'll just have to be careful to build up a valid format according to schema.org.
- `Pages.Directory.basePath` and `Pages.Directory.basePathToString` helpers.
- You can now use `StaticHttp` for your generated files! The HTTP data won't show up in your production bundle, it will only be used to produce the files for your production build.
- Added `Pages.PagePath.toPath`, a small helper to give you the path as a `List String`.

## [4.0.1] - 2020-03-28

### Added

- You can now host your `elm-pages` site in a sub-directory. For example, you could host it at mysite.com/blog, where the top-level mysite.com/ is hosting a different app.
  This works using [HTML `<base>` tags](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base). The paths you get from `PagePath.toString` and `ImagePath.toString`
  will use relative paths (e.g. `blog/my-article`) instead of absolute URLs (e.g. `/blog/my-article`), so you can take advantage of this functionality by just making sure you
  use the path helpers and don't hardcode any absolute URL strings. See https://github.com/dillonkearns/elm-pages/pull/73.

## [4.0.0] - 2020-03-04

### Changed

- `StaticHttp.stringBody` now takes an argument for the MIME type.

### Added

- `StaticHttp.unoptimizedRequest` allows you to decode responses of any type by passing in a `StaticHttp.Expect`.
- `StaticHttp.expectString` can be used to parse any values, like XML or plaintext. Note that the payload won't be stripped
  down so be sure to check the asset sizes that you're fetching carefully.

## [3.0.2] - 2020-02-03

### Fixed

- Fixed an issue where "Missing content" message flashed for the root page.
- Scroll up to the top of the page on page navigations (Elm's core Browser.application doesn't do this automatically). This change
  preserves the behavior for navigating to anchor links, so you can still go to a fragment and it will take you to the appropriate part
  of the page without scrolling to the top in those cases.

## [3.0.1] - 2020-01-30

### Changed

- Pass allRoutes into pre-rendering for https://github.com/dillonkearns/elm-pages/pull/60.

## [3.0.0] - 2020-01-25

### Changed

- Added URL query and fragment in addition to the PagePath provided by `init` and `onPageChange`.
  See [#39](https://github.com/dillonkearns/elm-pages/pull/39). The new data structure used looks like this:

```elm
    { path : PagePath Pages.PathKey
    , query : Maybe String
    , fragment : Maybe String
    }
```

## [2.0.0] - 2020-01-25

### Added

- There's a new `generateFiles` endpoint. You pass in a function that takes a page's path,
  page metadata, and page body, and that returns a list representing the files to generate.
  You can see a working example for elm-pages.com, here's the [entry point](https://github.com/dillonkearns/elm-pages/blob/master/examples/docs/src/Main.elm#L76-L92), and here's where it
  [generates the RSS feed](https://github.com/dillonkearns/elm-pages/blob/master/examples/docs/src/Feed.elm).
  You can pass in a no-op function like `\pages -> []` to not generate any files.

## [1.1.3] - 2020-01-23

### Fixed

- Fix missing content flash (that was partially fixed with [#48](https://github.com/dillonkearns/elm-pages/pull/48)) for
  some cases where paths weren't normalized correctly.

## [1.1.2] - 2020-01-20

### Fixed

- "Missing content" message no longer flashes between pre-rendered HTML and the Elm app hydrating and taking over the page. See [#48](https://github.com/dillonkearns/elm-pages/pull/48).

## [1.1.1] - 2020-01-04

### Fixed

- Don't reload pages when clicking a link to the exact same URL as current URL. Fixes [#29](https://github.com/dillonkearns/elm-pages/issues/29).

## [1.1.0] - 2020-01-03

Check out [this upgrade checklist](https://github.com/dillonkearns/elm-pages/blob/master/docs/upgrade-guide.md#upgrading-to-elm-package-110-and-npm-package-113) for more details and steps for upgrading your project.

### Added

- There's a new StaticHttp API. Read more about it in [this `StaticHttp` announcement blog post](http://elm-pages.com/blog/static-http)!
- The generated `Pages.elm` module now includes `builtAt : Time.Posix`. Make sure you have `elm/time` as a dependency in your project!
  You can use this when you make API requests to filter based on a date range starting with the current date.
  If you want a random seed that changes on each build (or every week, or every month, etc.), then you can use this time stamp
  (and perform modulo arithemtic based on the date for each week, month, etc.) and use that number as a random seed.

### Changed

- Instead of initializing an application using `Pages.application` from the generated `Pages` module, you now initialize the app
  using `Pages.Platform.application` which is part of the published Elm package. So now it's easier to browse the docs.
  You pass in some internal data from the generated `Pages.elm` module now by including
  this in the application config record: `Pages.Platform.application { internals = Pages.internals, ... <other fields> }`.
- Add init argument and user Msg for initial PagePath and page changes (see [#4](https://github.com/dillonkearns/elm-pages/issues/4)).

## [1.0.1] - 2019-11-04

### Fixed

- Generate files for extensions other than `.md` and `.emu` (fixes [#16](https://github.com/dillonkearns/elm-pages/issues/16)).
  As always, be sure to also use the latest NPM package.
