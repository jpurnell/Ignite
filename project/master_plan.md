# Ignite Master Plan

**Purpose:** Source of truth for this fork's direction and constraints.

> **Provenance:** Written 2026-08-05 from README, `Package.swift`, and the source tree.
> **This is a fork.** `upstream` is `twostraws/Ignite` with push disabled. This plan states
> what diverges; it does not restate upstream's mission.

---

## Project Overview

### Mission

A Swift static site generator. Upstream is a well-made, deliberately paced project that
doubles as teaching material. This fork carries work that is useful to run in production
now and is not upstream's priority to take.

### Fork position

As of 2026-08-05: **8 commits ahead, 1 behind**, merge base 2026-05-11, on
`feature/structured-data`.

### What diverges

- **Structured data** — JSON-LD with `@graph` support and node builders, so generated pages
  carry machine-readable schema rather than prose alone
- **Swift 6** — `Sendable` conformance throughout
- **Test rigour** — edge case, invalid input, property, and stress coverage; 232 test files
  against 337 sources

### Why fork rather than contribute

**[NEEDS INPUT]** — the honest answer belongs here. Pace, scope, or a direction upstream
would not want are all legitimate; leaving it unstated invites the assumption that the
divergence was accidental.

---

## The governing constraint

**Keep the public API compatible with upstream.** 419 public declarations. Merging upstream
must stay a routine operation rather than an archaeology project.

This is an architectural rule, not a preference. It means:

- New capability arrives as **additions** — new element types, new modifiers — not as
  changes to existing signatures
- A change that would force a caller to edit their site needs a reason strong enough to
  accept permanent divergence, and should be recorded as a decision
- Rendering output may differ; the API a site author writes against should not

The moment that rule is broken, `upstream` becomes decorative and this fork owns a static
site generator outright.

---

## Architecture

- **Language:** Swift 6 · **Build:** SwiftPM · **Testing:** Swift Testing
- **Dependencies:** `swift-markdown`, `swift-argument-parser`, `swift-collections`, `SwiftSoup`
- **Products:** `Ignite` (library), `IgniteCLI` (executable)

```
Sources/Ignite/
├── Elements/  Components/  Modifiers/  Styles/  Themes/   # authoring surface
├── Rendering/ Generation/  Publishing/                    # HTML out
├── Framework/ Types/  Actions/  Extensions/               # core
├── Resources/ QR/                                         # assets
└── Ignite.docc/
```

---

## Current Status

- [x] Structured data with `@graph`, Swift 6 `Sendable`, expanded tests
- [ ] One commit behind upstream

### Priorities

1. **Stay mergeable.** Distance from upstream is the metric to watch; 8/1 is healthy, and
   a year of drift would not be.
2. **[NEEDS INPUT]** — the larger plan. Structured data points toward `GeoSEOMCP`'s
   AI-visibility work, making this the generator half of a generate-then-audit pipeline,
   but that is inference from commits rather than a stated goal.

## Quality Standards

`coding_rules.md`, Swift 6 strict concurrency, zero warnings, DocC on public types.
**Structured-data output is tested against fixed expected JSON-LD** — schema.org correctness
is not eyeballable, and a malformed `@graph` fails silently at the consumer.

## Roadmap

**[NEEDS INPUT]** — see Priorities. Any phase that would break the public API belongs here
with its justification, because it ends the merge relationship.

---

**Last Updated:** 2026-08-05
