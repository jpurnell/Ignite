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

### Changed

- Most force unwraps, `fatalError` calls and other traps were removed from the
  library, the command-line tool and the tests, in favour of thrown errors,
  build warnings and safe fallbacks. Four public paths still trap:
  `KeyframeProxy.callAsFunction` outside 0%–100%, `Text(placeholderLength:)`
  below 1, `Article.type`, and `NavigationItem.markup()`.
- The publish pipeline throws `PublishingError` where it used to stop the
  process with `fatalError`.
- Out-of-range `Color` components given as `Double` are clamped: red, green,
  blue and white to 0 through 255, opacity to 0% through 100%. A component
  above 1 used to pass through as a value above 255. The initializer that
  takes `Int` components does not clamp.
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
