# Changelog

Changes to this fork of [Ignite](https://github.com/twostraws/Ignite). The fork
diverges from upstream on purpose; this file records only what the fork changed.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `PublishingOutput`, which says where a publish writes its results – the
  warnings and errors collected during the build, and whether it completed.
  `.standard` writes to standard output and is the default, `.standardError`
  writes to standard error, and `PublishingOutput(sink:)` hands each line to a
  closure of your own.
- `Site.publish(from:buildDirectoryPath:logOptions:output:)` and
  `Site.publish(sourceDirectory:buildDirectory:logOptions:output:)`, which
  publish a site and write its results to a `PublishingOutput` you choose. The
  existing `publish` methods are unchanged and write to standard output.
- `String.javaScriptStringLiteral()`, which writes a string as a complete,
  quoted JavaScript string literal that no input can end early. Use it in your
  own `Action` types wherever a Swift string becomes a JavaScript string. It is
  safe in an event attribute and inside a `<script>` element.

### Fixed

- A site with only a dark theme has its theme written into `:root`. The
  `:root` ruleset that carries the theme's CSS variables was built and then
  dropped, so `ignite-core.min.css` contained the theme's media queries and
  global rules but none of its colors, fonts or sizes, and the site rendered
  with Bootstrap's defaults. Sites with a light theme, or with alternate
  themes, generate the same CSS as before.
- A font whose source string is not a URL no longer crashes the build. The font
  is created without a source file, referenced by name only, and a warning is
  added to the build.
- Front matter with CRLF or CR line endings is parsed; previously only LF was
  recognised as a line break.
- Front matter that opens with `---` and never closes it no longer crashes. The
  file is treated as having no front matter.
- `Color` no longer traps on a component that is NaN, infinite, or outside the
  range of `Int`. NaN is treated as 0.
- `Carousel` no longer traps on a slide duration that is NaN, infinite, or too
  large to express in whole milliseconds. Such a duration renders as no
  interval.
- `aspectRatio(0)` no longer emits an infinite percentage. A ratio that is not
  positive falls back to square.
- `Transition.speed(0)` no longer produces an infinite duration. A speed that
  is not positive leaves the duration unchanged.
- `Article.date` returns the same instant on every read when the article has no
  date. It used to return the current time afresh on each read, so two reads of
  the same article disagreed. Articles that declare a date, and articles loaded
  from a file, are unaffected.
- The command-line tool's process helper reads both of a command's pipes while
  it runs, so a command that writes more than a pipe holds no longer stalls.
- Numbers written into HTML attributes and CSS no longer follow the locale of
  the machine running the build. They were formatted for a reader, so a value
  of 1,000 or more gained a grouping separator under `en_US` (`5,000`), a
  different one elsewhere (`5.000`, `5 000`), and under locales with their own
  digits even small values changed (`٤٠٠` for a font weight of 400). Values
  below 1,000 built under `en_US` are written exactly as before. Affected:
  - `Carousel` `data-bs-interval`: a slide duration of one second or more.
    Five seconds is now `5000`; it was `5,000`, which Bootstrap cannot read.
  - `CodeBlock.lineNumberVisibility` and the site-wide line number setting on
    `Body`, `data-start`: a first line of 1,000 or more.
  - `Column.columnSpan`, `colspan`: a span of 1,000 or more.
  - `Text.lineLimit`, `--ig-max-line-length`: a limit of 1,000 or more.
  - `lineSpacing` with an exact value, `line-height`: 1,000 or more
    (`1234.5`, not `1,234.5`). The same format writes `opacity`, whose values
    never reach 1,000 and are unchanged.
  - `font-weight` from `fontWeight` and `font`, and the underline opacity
    classes of `Link`: unchanged under `en_US`; fixed under locales that do
    not use ASCII digits.
- Front-matter dates are read in the Gregorian calendar whatever the locale of
  the machine running the build. Under a locale with another calendar the same
  `date: 2024-03-05` was read as a different year (1481 under `th_TH`). Dates
  parsed under Gregorian-calendar locales are unchanged.
- An element ID or message can no longer break out of the JavaScript an action
  generates. `ToggleElementVisibility`, `ShowElement`, `HideElement`,
  `DismissModal` and `ShowModal` wrote the ID straight into a single-quoted
  string, so an ID containing `'`, a backslash, a line break or `</script>`
  ended the string and ran as code; `ShowAlert` escaped `'` but not a backslash
  or a line break. All of them, along with `SwitchTheme`, hover effect values,
  the table filter and the Google Analytics measurement ID, now go through
  `javaScriptStringLiteral()`. IDs and messages made of letters, digits,
  spaces and ordinary punctuation generate the same JavaScript as before.
  - `ShowAlert` writes a double quote in its message as `\u0022` where it wrote
    `&quot;`. Both show a `"` in the alert.
  - A hover effect whose value contains a quote, such as a quoted font family,
    used to generate JavaScript that did not parse; the quote is now escaped.
- `CustomAction` no longer rewrites the JavaScript it is given. It put a
  backslash before every `'`, which is only right inside a string, so
  `CustomAction("document.title = 'Hello'")` produced code that did not parse.
  `compile()` now returns the code as written.
- The JavaScript of every event attribute (`onclick` and the rest) has its
  double quotes written as `&quot;`, so JavaScript containing a `"` cannot end
  the attribute. `CustomAction` used to do this for itself and its markup is
  unchanged; an `Action` of your own that returns a `"` is now handled too.
- `BreakpointQuery` values that are equal now hash alike. `==` compared the
  themes of two queries by prefix – the left theme's ID starting with the
  right's – which is not symmetric, while `hash(into:)` hashed the whole ID, so
  two queries could be equal one way round and not the other, and equal queries
  could land in different buckets of a `Set` or `Dictionary`. Two queries are
  now equal when they have the same breakpoint and the same theme ID, or no
  theme. Nothing in Ignite relied on the prefix match – themed queries are
  created and turned straight into media features – and generated CSS is
  unchanged.
- `Card.cardStyle(.solid)` and `.cardStyle(.bordered)` on a card with no role
  no longer emit `text-bg-default` and `border-default`, which are not
  Bootstrap classes. Bootstrap defines those classes for its eight theme colors
  only, so a card whose role is `.default`, `.none` or `.close` now carries
  `card` alone and looks like a default card. Cards with any other role are
  unchanged.
- `Modal` no longer points `aria-labelledby` at an element that does not exist.
  Every modal carried `aria-labelledby="modalLabel"` and nothing had that ID. A
  modal with a header now gives the header the ID `<modal ID>-label` and refers
  to that, so two modals on a page are labelled separately; a modal with no
  header, or with an empty ID, has no `aria-labelledby` attribute.
- robots.txt follows the Robots Exclusion Protocol (RFC 9309) more closely:
  - `DisallowRule(name:)` and `DisallowRule(robot:)` write `Disallow: /`. They
    wrote `Disallow: *`, which is not a path and matches nothing.
  - A path given without its leading slash is written with one: `private`
    becomes `Disallow: /private`. Paths that begin with `/` are unchanged.
  - A rule for the user agent `*` replaces the closing `User-agent: *` /
    `Allow: /` group instead of being followed by it. Crawlers merge groups for
    the same agent and prefer `Allow` when both match equally, so the closing
    group cancelled `DisallowRule(name: "*")`.
  - The `Sitemap` line has one slash before `sitemap.xml` when the site's URL
    ends in a slash; it had two.
  - A robot name or path containing a line break can no longer start a new
    line of the file.
- `Color(red:green:blue:opacity:)` with `Int` components clamps them, as the
  `Double` initializers do: red, green and blue to 0 through 255, opacity to 0%
  through 100%. Out-of-range values used to pass straight into the CSS, as in
  `rgb(300 -5 128 / 150%)`, and an opacity that was not a number stopped the
  build. In-range colors are unchanged. One visible consequence: an eight-digit
  hex color whose last two digits are above `64` is written with 100% opacity
  where it was written with up to 255%, which browsers already drew as 100%.

### Changed

- `BoolMatrix.flattened` and `Array2D.flattened` are removed from the command-line
  tool. Nothing read either; a stale index unit had been hiding that from the
  unreachable-code check.

- Force unwraps, `fatalError` calls and other traps were removed from the
  library, the command-line tool and the tests, in favour of thrown errors,
  build warnings and safe fallbacks. No `fatalError` or `precondition` is left
  in the library. The last of them now behave as follows:
  - `KeyframeProxy.callAsFunction` – and so every keyframe – moves a position
    outside 0%–100% to the nearer end and adds a build warning. A position that
    is not a number goes to 0%.
  - `Text(placeholderLength:)` asked for fewer than 1 word produces empty text
    and adds a build warning.
  - `Article.type` is the empty string for content with no type: a Markdown
    file directly in Content, and the empty article a non-article page reads
    from `@Environment(\.article)`.
  - A type of your own that conforms to `NavigationItem` or `FormItem` renders
    its `body`, like any other element you write.
  - `FeedConfiguration.FeedImage` given a size beyond the RSS limit of 144 by
    400 pixels declares the image at the limit and adds a build warning.
  - An accordion `Item` rendered outside an `Accordion` renders on its own and
    adds a build warning.
  - A `Layout` whose `body` is not a document, a `Body` or block HTML – only
    possible by bypassing `@DocumentBuilder` – is rendered as the content of a
    body.
  - `Percentage.roundedValue` returns 0 for a percentage that is not a number,
    and the nearest `Int` for one beyond `Int`'s range.
  - Rendering with no publish in progress – calling `markup()` from a test or a
    script of your own – no longer stops the process. Elements that read site
    settings see a placeholder site with every default, and anything they
    record is discarded, since there is no build to report it to. A warning goes
    to the unified log. Inside `Site.publish()` nothing changes.
- The publish pipeline throws `PublishingError` where it used to stop the
  process with `fatalError`.
- Out-of-range `Color` components given as `Double` are clamped: red, green,
  blue and white to 0 through 255, opacity to 0% through 100%. A component
  above 1 used to pass through as a value above 255. The initializer that
  takes `Int` components clamps to the same ranges.
- Vimeo, YouTube and Spotify embed IDs are percent-encoded into the path of the
  embed address, so an ID cannot change the host or the query.
- The command-line tool runs commands as argument arrays, directly, rather than
  as a string handed to `bash -c`. Every run has a timeout; a command that
  outlives it is sent SIGTERM and then SIGKILL, and reading its output is given
  a bounded time to finish after it exits.
- `Text(placeholderLength:)` produces the same placeholder text on every build
  instead of different text each time, so a generated site is reproducible. A
  new initializer, `Text(placeholderLength:using:)`, takes a caller's random
  number generator.
- The command-line tool writes its ❌ failure messages, and the compiler errors
  it relays from a failed build, to standard error rather than standard
  output.
- Diagnostics – what failed underneath a warning, and why – also go to the
  unified log, under the subsystem `org.roseclub.ignite`. Read them with
  `log stream --predicate 'subsystem == "org.roseclub.ignite"'`.
- Internal declarations that nothing referenced were removed. No public API
  and no generated HTML or CSS changes as a result.
- Tests assert exact expected values, and tests that draw random input use a
  seeded generator.
- `swift-tools-version` is raised from 6.0 to 6.2.
- The package depends on `swift-docc-plugin`, so its documentation can be built
  and checked with `swift package generate-documentation`.

## [0.6.9] - 2026-04-21

The upstream release this fork last tagged, and the baseline the entries above
are measured from. It is not a release of this fork: see the
[upstream release notes](https://github.com/twostraws/Ignite/releases/tag/0.6.9)
for what it contains. The fork's own commits since that tag – Atom and JSON
feeds, the `StructuredData` element, and Swift 6 `Sendable` adoption – predate
this file and are recorded in the Git history.

[Unreleased]: https://github.com/jpurnell/Ignite/compare/0.6.9...HEAD
[0.6.9]: https://github.com/twostraws/Ignite/releases/tag/0.6.9
