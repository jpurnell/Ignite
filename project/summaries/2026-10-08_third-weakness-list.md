# Session Summary: A Third List of Known Weaknesses

| Date | Phase | Status |
| :--- | :--- | :--- |
| 2026-10-08 | Fix known weaknesses, test-first; reconcile documentation and plan | COMPLETED |

## 1. Core Objective

Fix a third list of twelve known weaknesses in the fork – library, command-line tool,
documentation and plan – under the standing rule that a known weakness in a shipped product
is fixed, not documented. Every fix began with a failing test asserting exact output.

## 2. Work Completed

Branch `main`, from `d70c81ad`. Tests went from 1,535 to 1,703 (1,629 library, 74
command-line tool). The strict gate passes.

| Commit | What |
| :--- | :--- |
| `a6820928` | `btn-close` alone for close buttons; `file:` addresses written as authored (the "dead" branch of `path(for:)` was reachable and wrong); `Spacer` on both axes; `Array.localizedContains` removed |
| `dfbc60b6` | Icons named or hidden; `Label`, `Button`, `FeedLink` icons decorative; table header scope and filter name; hidden-label fields keep `aria-label`; `ControlGroup` label wired; warnings for unnamed buttons and fields; no `btn` on component buttons |
| `8a36fbb0` | `RawTextElement` neutralises `</style`, `</script`; `StructuredData` addresses absolute; full HTML character reference decoding from a generated WHATWG table |
| `9dc92c44` | Relative-path sites name each page's file; `LinkResolution` test helper follows every `href`/`src` of a published site across three shapes |
| `2c28cfb7` | `IgniteCLITesting`: commands behind a `CommandContext`, process helper against real children, the built tool's exit status, QR grids |
| (this commit) | README and DocC catalogue reconciled; *Migrating from upstream Ignite* article; master plan reconciled |

### What the new tests found that was not on the list

- The `NavigationBar` logo and `FeedLink` linked to the root of the host on a subsite.
- Root-relative Markdown links were left as `/` on a relative-path site.
- The JSON feed was titled "JSON Feed Feed".
- The process helper returned empty output with status 0 when commands ran from concurrent
  tasks: its dispatch channels starved once the concurrency pool was full of waiting threads.
- `ignite run` exited 0 when the local server died, and took `about:blank` for a subsite.
- `make install` exited 0 after printing "Installation failed".

## 3. Decisions Made

- **`file:` URLs are addresses with a scheme**, written as authored like `tel:`. The branch
  that handled them was removed because removing it *is* the correct behaviour.
- **A `ControlGroup` is labelled as a group** (`role="group"`, `aria-labelledby`) rather than
  by pointing its `<label>` at the first field, because a group may hold several fields or none.
- **`<script` is escaped only after an unclosed `<!--`.** Escaping every `<!--` would break
  the old HTML-comment idiom in scripts; only the pair leaves the element open.
- **Structured-data addresses are completed when a node is built**, since the node builders
  return plain dictionaries. Built outside a publish they are returned unchanged and logged.
- **Markdown addresses are resolved per page only on relative-path sites.** On absolute-path
  sites they stay as authored, because the list said those sites must not change.
- **Pipes are read on their own threads.** The helper's interface is unchanged; only how
  `PipeDrain` reads was replaced, with a red test showing the lost output first.
- **The process-based test suites are serialized**, so they never hold the whole concurrency
  pool at once.

## 4. Not Changed (owner decisions pending)

- Trailing slash on canonical URLs, `og:url`, feed links/GUIDs and JSON-LD `url`.
- An article's date when front matter has none (file timestamp today).
- `Color.opacity` as an `Int` percentage.

## 5. Next Steps

The known weaknesses found and not fixed are listed in `project/master_plan.md` under
Roadmap. The first two need an owner decision before code: what a root-relative Markdown
address means on a subsite, and whether `ignite new` should build new sites against this fork.

## 6. Housekeeping Note

`project/summaries/2026-06-10_fix_adaptive_breathing_glasses_telemetry.md` describes another
project's session and appears to have been committed here by mistake. It was left in place.
