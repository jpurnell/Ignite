# Ignite Master Plan

**Purpose:** Source of truth for this fork's direction and constraints.

> **Provenance:** Written 2026-08-05 from README, `Package.swift`, and the source tree.
> Reconciled 2026-10-08 against what shipped that week; superseded statements are struck
> through rather than removed, so the plan shows where it was out of date.
> **This is a fork.** `upstream` is `twostraws/Ignite` with push disabled. This plan states
> what diverges; it does not restate upstream's mission.

---

## Project Overview

### Mission

A Swift static site generator. Upstream is a well-made, deliberately paced project that
doubles as teaching material. This fork carries work that is useful to run in production
now and is not upstream's priority to take.

### Fork position

~~As of 2026-08-05: **8 commits ahead, 1 behind**, merge base 2026-05-11, on
`feature/structured-data`.~~

As of 2026-10-08: the fork's line of work is **`main`**, tracking `origin/main`
(`jpurnell/Ignite`). It is **32 commits ahead and 1 behind** the local `upstream/main` ref,
with the same merge base (`64fb3ff6`, 2026-05-11). That ref is upstream as last fetched – its
tip is dated 2026-06-18 – and was not fetched again for this reconciliation, so "1 behind" is
a floor, not a measurement.

**No pull requests are open against upstream** (`gh pr list --repo twostraws/Ignite
--author jpurnell --state open` returned nothing on 2026-10-08). Five earlier ones were
merged upstream, the last in April 2026 (Atom and JSON feeds); nine opened in May 2026 –
structured data, the stronger test assertions and seven "foundations" branches – were closed
unmerged. The fork is maintained as a full, separate fork: nothing is pushed to upstream and
nothing is proposed to it from here.

### What diverges

- **Structured data** — JSON-LD with `@graph` support and node builders, so generated pages
  carry machine-readable schema rather than prose alone
- **Swift 6** — `Sendable` conformance throughout
- **Test rigour** — edge case, invalid input, property, and stress coverage; ~~232 test files
  against 337 sources~~ 278 test files against 355 sources, 1,703 tests (2026-10-08)

Added the week of 2026-10-05, and recorded entry by entry in `CHANGELOG.md` (`[Unreleased]`)
and, for a site author, in `Sources/Ignite/Ignite.docc/MigratingFromUpstream.md`:

- **Atom and JSON feeds** beside RSS (merged upstream in April; listed here because the
  changelog's baseline predates it)
- **Escaping on output** — attribute values, titles, Markdown text and code are escaped; a
  string used as an element is still HTML, and `Text(verbatim:)` shows one as written.
  JavaScript strings, CSS strings, `<style>` and `<script>` content, feeds and JSON-LD each
  have one escaper
- **Reproducible builds** — numbered element IDs, content-derived animation classes, fixed
  ordering everywhere a dictionary or the file system used to decide it
- **Paths** — sites deployed in a subdirectory link to themselves; `useRelativePaths` sites
  open from a folder; metadata and structured-data addresses are absolute; no `robots.txt`
  on a subsite
- **No traps** — every `fatalError` and `precondition` in the library replaced by a build
  warning with a fallback, or a thrown `PublishingError`; `PublishingOutput` chooses where a
  build reports
- **CSS-correct colors** — hex alpha read as CSS defines it, components clamped
- **Bootstrap-correct markup and accessible names** — only classes Bootstrap defines; icons,
  icon buttons, table headers and unlabelled fields named or hidden
- **Full HTML character reference decoding** for titles and descriptions, from a table
  generated from the WHATWG list
- **A command-line tool that scripts can trust** — non-zero exit on every failure, success
  judged by the child's exit status, ❌ on standard error, and its own test target

### Why fork rather than contribute

**[NEEDS INPUT]** — the honest answer belongs here. Pace, scope, or a direction upstream
would not want are all legitimate; leaving it unstated invites the assumption that the
divergence was accidental.

---

## The governing constraint

**Keep the public API compatible with upstream.** ~~419 public declarations.~~ 1,337 public
APIs as the gate's `doc-coverage` checker counts them (2026-10-08), all documented. Merging
upstream must stay a routine operation rather than an archaeology project.

This is an architectural rule, not a preference. It means:

- New capability arrives as **additions** — new element types, new modifiers — not as
  changes to existing signatures
- A change that would force a caller to edit their site needs a reason strong enough to
  accept permanent divergence, and should be recorded as a decision
- Rendering output may differ; the API a site author writes against should not

The moment that rule is broken, `upstream` becomes decorative and this fork owns a static
site generator outright.

**How the rule has held (2026-10-08).** The week's work stayed inside it as written: every
change to the API was an addition (`PublishingOutput` and the `publish` methods that take
one, `Text(verbatim:)`, `Link(_:sitePath:)`, `String.escapedForHTML()`,
`String.javaScriptStringLiteral()`), and no public declaration was removed or renamed. Two
things strain it and are recorded rather than argued away:

- **Rendering output differs a great deal.** The rule allows that, but the allowance was
  written when the difference was structured data. Escaping, numbered IDs, subsite links and
  Bootstrap class changes mean almost every page of a site differs from upstream's. A site
  author moving in either direction has reading to do; the migration article is that reading.
- **`swift-tools-version` is 6.2, upstream's is 6.0.** A caller on an older toolchain can
  build upstream and not this fork.

Compatibility with upstream's API is asserted by the way the work was done, not tested: there
is no check that builds a site against both. That is open work (see Roadmap).

---

## Architecture

- **Language:** Swift 6 (tools 6.2) · **Build:** SwiftPM · **Testing:** Swift Testing
- **Dependencies:** `swift-markdown`, `swift-argument-parser`, `swift-collections`, `SwiftSoup`,
  `swift-docc-plugin`
- **Products:** `Ignite` (library), `IgniteCLI` (executable)
- **Test targets:** `IgniteTesting` (library, 1,629 tests), `IgniteCLITesting` (command-line
  tool, 74 tests; added 2026-10-08)

~~`Rendering/ Generation/ Publishing/` and `Resources/ QR/` under `Sources/Ignite/`~~ – the
tree below is the one in the repository; there was never a `Generation` directory, and the QR
code belongs to the command-line tool.

```
Sources/Ignite/
├── Elements/  Components/  Modifiers/  Styles/  Themes/   # authoring surface
├── Rendering/ Publishing/                                 # HTML, CSS, feeds out
├── Framework/ Types/  Actions/  Extensions/               # core
├── Resources/                                             # Bootstrap, icons, scripts
└── Ignite.docc/                                           # catalogue + migration article
Sources/IgniteCLI/
├── BuildCommand  NewCommand  RunCommand                   # the three commands
├── CommandContext  Process-Execute  Output                # everything they reach outside
└── QR Generation/                                         # the code `ignite run` prints
scripts/
└── generate-html-named-character-references.py            # WHATWG list → Swift table
```

---

## Current Status

- [x] Structured data with `@graph`, Swift 6 `Sendable`, expanded tests
- [x] `main` is the line of work; no pull requests open against upstream (2026-10-08)
- [x] Clean strict quality gate, enforced by pre-commit and pre-push hooks
- [x] Escaping on output; one escaper each for HTML, JavaScript, CSS, raw-text elements
- [x] Reproducible builds: two builds of an unchanged site write identical files
- [x] Subsite links, page-relative paths, absolute metadata and structured-data addresses
- [x] Relative-path sites open from disk; every `href`/`src` of a published site is followed
      in tests, for a relative site, a root site and a subsite
- [x] No `fatalError`/`precondition` left in the library; `PublishingOutput`
- [x] CSS-correct hex alpha; clamped color components
- [x] Accessible names for icons, icon buttons, table headers, hidden-label fields
- [x] Command-line tool: non-zero exit on failure, exit status decides success, test target
- [x] DocC catalogue and README reconciled; migration article written
- [ ] One commit behind upstream (as last fetched; see Fork position)

Owner decisions pending – deliberately **not** changed, and not to be changed without one:

- Whether canonical URLs, `og:url`, feed links and GUIDs, and the JSON-LD `url` gain a
  trailing slash. Links do (`/about/`); these do not (`https://example.com/about`).
- What an article's date is when its front matter has none. Today it is the file's timestamp.
- Whether `Color.opacity` becomes a fractional value. Today it is an `Int` percentage.

### Priorities

1. **Stay mergeable.** Distance from upstream is the metric to watch; ~~8/1 is healthy~~, and
   a year of drift would not be. It is 32/1 two months on. The plan called 8 healthy and did
   not say what would not be; 32 commits that touch most of the rendering path is well past
   the point where a merge from upstream is routine, and the next one should be attempted
   soon to find out what it costs, rather than assumed cheap.
2. **[NEEDS INPUT]** — the larger plan. Structured data points toward `GeoSEOMCP`'s
   AI-visibility work, making this the generator half of a generate-then-audit pipeline,
   but that is inference from commits rather than a stated goal.

## Quality Standards

`coding_rules.md`, Swift 6 strict concurrency, zero warnings, DocC on public types.
**Structured-data output is tested against fixed expected JSON-LD** — schema.org correctness
is not eyeballable, and a malformed `@graph` fails silently at the consumer.

As practised since 2026-10-05:

- **Test first, exact output.** A failing test asserting the exact generated markup comes
  before the change, and what correct input produced before is pinned so only broken cases move.
- **The gate is strict and unsuppressed.** `quality-gate --check all --exclude test --strict
  --continue-on-failure` exits 0; no override comments, no configuration exclusions beyond the
  two checkers recorded in `.quality-gate.yml` as unable to evaluate this package.
- **Every output change is in `CHANGELOG.md`**, written for a site author.
- **A built site is followed, not just its elements.** `LinkResolution` resolves every
  reference in a published site the way a folder or a server would.

## Roadmap

**[NEEDS INPUT]** — see Priorities. Any phase that would break the public API belongs here
with its justification, because it ends the merge relationship.

Known weaknesses, found on 2026-10-08 and not fixed, each small enough to schedule:

- **Markdown links and images from the root on a subsite.** `[About](/about)` and
  `![](/images/a.png)` are written as authored, so on `https://example.com/docs` they leave
  the site – while the same HTML in the feeds is completed with the site's address. There is
  no Markdown equivalent of `Link(_:sitePath:)`. Needs an owner decision on what a
  root-relative Markdown address means.
- **`ignite new` builds a site against upstream.** The starter template it clones depends on
  `twostraws/Ignite`. Needs a fork of the template, or a rewrite of the dependency after
  cloning.
- **`Style` resolution is slow.** `StyleManager` evaluates a style under every combination of
  environment conditions: about ten seconds per custom `Style` in a debug build, and a
  `MetaStyle` pays it on every render. Needs a cache at least, and a smarter search at best.
- **No check that the fork still compiles a site written for upstream.** The governing
  constraint is unverified. Needs a fixture site built against both.
- **A `NavigationBar` always uses the ID `navbarCollapse`**, so two on a page collide.
- **The 404 page of a relative-path site** has paths relative to the root, and a server shows
  it for missing pages at any depth.
- **`ignite run` reports a server that died only when Return is pressed**, and its port search
  stops at 8999 with a message that names 8000–8999 whatever `--port` was.
- **Version strings.** The tool reports `0.6.0` and pages carry `Ignite v0.6.0` in their
  generator tag, against a 0.6.9 baseline.

---

**Last Updated:** 2026-10-08 — reconciled with the week's work: fork position (`main`, 32
ahead / 1 behind, no pull requests open upstream), the list of divergences, the architecture
tree (which named two directories that do not exist), the public API and test counts, Current
Status, the owner decisions still pending, and a first list of known weaknesses under
Roadmap. The 2026-08-05 figures are struck through, not deleted. The two `[NEEDS INPUT]`
sections are still the owner's to write.
