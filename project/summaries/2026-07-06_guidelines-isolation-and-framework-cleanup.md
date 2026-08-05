# Session Summary: Guidelines Isolation, setup.swift Root-Cause Fix, and Ignite Framework Cleanup

| Date | Phase | Status |
| :--- | :--- | :--- |
| 2026-07-06 | Infrastructure / guidelines hygiene | COMPLETED |

## 1. Core Objective

Stop project-specific content from leaking into the shared `development-guidelines`
template, fix the underlying cause so it can't recur, and de-risk the third-party
Ignite framework checkout that hosts this clone.

## 2. Work Completed

### Fleet-wide guidelines isolation
- Audited **all 52** nested `development-guidelines` clones across the corpus.
- Migrated the **40** that were on `main` onto their own `project-state/<project>` branches
  (pending content preserved and pushed), so none can commit to the shared template `main`.
- Caught **2 more attached as git submodules** (`SwiftDesignKit`, `BusinessMathMarketData`) —
  missed by a `[ -d .git ]` audit because a submodule's `.git` is a *file*. Both isolated.
- Final root-level re-scan: **zero** guidelines repos (clone or submodule) left on `main`.

### setup.swift — permanent root-cause fix (template `main` = 2e64aa2)
- The template's generator now, on every run: gitignores the nested folder in the outer repo
  AND switches the clone to `project-state/<project>` (idempotent) — fresh clones can never
  start on `main`.
- Restored `setup.swift` itself, which the README referenced but `origin/main` was missing.
- **Incident + recovery:** the first publish accidentally replaced the newer template
  `setup.swift`, dropping its `.quality-gate.yml` / `generateQualityGateConfig` feature.
  Detected immediately; re-published an add-only version preserving both features.

### Ignite framework checkout (`Swift/Ignite`) de-risking
- **Remotes:** `origin` → `jpurnell/Ignite` (your fork), `upstream` → `twostraws/Ignite`
  with push disabled — no more accidental pushes toward the third-party upstream.
- **Stray site projects** relocated out of the framework checkout to `Swift/` siblings
  (per "siblings not nested"): homepage, homesite, geoauditors, Princeton2000,
  tawanaForDistrict1, liquidAsset. Obsolete ones archived to `Swift/_archive/`.
- **This clone (orphan):** its `main` was an unrelated April history with no common ancestor
  to the live template. Reconciled onto the real template (`main` → `origin/main`, now on
  `project-state/ignite`); the orphan history is preserved in tag `orphan-history-2026-04`.

## 3. Design Decisions

- **project-state isolation over detaching:** keeps the framework's recovery model intact.
- **Additive publish, never force-push, to the shared template:** the orphan's 27 commits were
  superseded, so only the salvageable `setup.swift` was forward-committed onto `origin/main`.

## 4. Next Steps

- Optionally push `project-state/ignite` if you want this clone's state backed up remotely.
- Parent submodule repos (SwiftDesignKit, BusinessMathMarketData) now show
  `M development-guidelines`; accept the gitlink bump when convenient.
