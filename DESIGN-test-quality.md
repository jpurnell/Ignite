# Design Proposal: Ignite Test Suite Quality Baseline

**Branch:** `test/quality-baseline`
**Scope:** Fix existing test quality issues + fill coverage gaps for testable framework code
**Goal:** Establish a clean, comprehensive test baseline before adding new features

---

## Current State

- **1,228 tests** across 8 categories, all passing
- **Quality gate:** 12 errors, 25 warnings from `test-quality` checker
- **Coverage gaps:** 48 source files lack test counterparts (mostly Framework)

---

## Part 1: Fix Existing Test Quality Issues

### 1A. Float Equality (5 fixes)

Replace exact `==` comparisons on floating-point values with tolerance-based assertions.

| File | Line | Current | Fix |
|------|------|---------|-----|
| `Framework/AnimatableData.swift` | 61 | `data.duration == 0.35` | `abs(data.duration - 0.35) < 1e-6` |
| `Framework/Animation.swift` | 30 | `animation.duration == 2.0` | `abs(animation.duration - 2.0) < 1e-6` |
| `Framework/Animation.swift` | 44 | `animation.duration == 0.5` | `abs(animation.duration - 0.5) < 1e-6` |
| `Framework/Animation.swift` | 50 | `animation.duration == 0.5` | `abs(animation.duration - 0.5) < 1e-6` |
| `Framework/Animation.swift` | 57 | `animation.duration == 0.5` | `abs(animation.duration - 0.5) < 1e-6` |

Note: `Types/Percentage.swift` lines 39/45 already use tolerance — quality-gate flagged the
subtraction test at line 39 which uses `==` on the result of `Percentage - Percentage`. The
operator returns a `Percentage` (not raw Double), so the fix is the same pattern on the result's
underlying value.

### 1B. Force Try (2 fixes)

Both in `String-TestingHTML.swift`, a test helper used across the suite. The `try!` calls
construct regex patterns from known-good strings. Replace with throwing functions:

| File | Line | Current | Fix |
|------|------|---------|-----|
| `String-TestingHTML.swift` | 19 | `try! Regex(...)` | Make function `throws`, use `try` |
| `String-TestingHTML.swift` | 36 | `try! Regex(...)` | Make function `throws`, use `try` |

Since these are helper methods called by many tests, marking them `throws` propagates
cleanly — callers are already `async throws` test functions.

### 1C. Weak Assertions → `#require()` (22 fixes)

Most weak assertions are nil-checks where the result is used by subsequent assertions.
Replace `#expect(x != nil)` with `let x = try #require(x)` so tests fail fast with
clear diagnostics.

| File | Lines | Pattern |
|------|-------|---------|
| `Publishing/JSONFeedGenerator.swift` | 106 | `!= 0` → specific count |
| `Publishing/ThemeHelpers.swift` | 109, 110 | `!= nil` → `#require()` |
| `Modifiers/HoverEffect.swift` | 65, 66 | `!= nil` → `#require()` |
| `Modifiers/MediaQuery.swift` | 143 | `!= nil` → `#require()` |
| `Modifiers/TransitionModifier.swift` | 23, 39, 40, 57 | `!= nil` → `#require()` |
| `Framework/FeedConfiguration.swift` | 32 | `!= nil` → `#require()` |
| `Framework/ElementTypes.swift` | 131 | `!= nil` → `#require()` |
| `Elements/NavigationBar.swift` | 20, 31, 107, 177, 213 | `!= nil` → `#require()` |
| `Elements/HTMLDocument.swift` | 27 | `!= nil` → `#require()` |
| `Elements/Accordion.swift` | 34 | `!= nil` → `#require()` |
| `Elements/StructuredData.swift` | 505 | `!= 0` → specific count |

### 1D. Unseeded Random (3 fixes)

Replace non-deterministic random calls with fixed test data or seeded generators.

| File | Line | Current | Fix |
|------|------|---------|-----|
| `Extensions/Array-ContainsLocation.swift` | 55 | `Int.random(in: 1...count)` | Fixed value or seeded RNG |
| `Extensions/Array-ContainsLocation.swift` | 60 | `Double.random(in: 0...1)` | Fixed value or seeded RNG |
| `Extensions/Array-Sorting.swift` | 188 | `Bool.random()` | Fixed value |

---

## Part 2: New Test Coverage

### 2A. Needs Tests (10 files — real logic that should be verified)

| File | Lines | What to Test |
|------|-------|-------------|
| **Framework/Article.swift** | 311 | `processMetadata()` YAML parsing, `resolveTitle()` fallback chain, `populateMetadataDates()` format parsing, `estimatedReadingMinutes` calculation, `tagLinks()` |
| **Framework/Color.swift** | 637 | `init(hex:)` parsing (3/4/6/8-digit, with/without #), `opacity()`, `weighted()` color mixing, static color constants spot-checks |
| **Framework/DecodeAction.swift** | 85 | `data(forResource:)` file loading, `callAsFunction` JSON decoding, error handling for missing files and malformed JSON |
| **Framework/EmailPlatform.swift** | 105 | Each platform's `endpoint`, `customAttributes`, `script` computed properties |
| **Framework/Event.swift** | 38 | Init from EventType vs name string, `==` / `<` ordering, `hash(into:)` |
| **Framework/Markup.swift** | 124 | String interpolation with CoreAttributes, pendingRegistrations tracking, `+` / `+=` operators, `joined()` |
| **Framework/Site.swift** | 359 | `allHighlighterThemes` aggregation, `allThemes` dedup, default property values |
| **Elements/LinkGroup.swift** | 132 | `renderPrivacyProtectedLink()` base64 encoding, `renderStandardLink()` href processing, `target()` / `relationship()` modifiers |
| **Elements/PlainDocument.swift** | 53 | Full document markup with `<!doctype>`, language attribute, theme data attributes, head/body ordering |
| **Framework/Material.swift** | 62 | `className` CSS class generation, `colorScheme()` override |

### 2B. Low Priority (30 files — simple types, smoke tests only if time permits)

These are protocols with trivial default implementations, small enums, empty conformances,
or simple wrappers. They add coverage breadth but minimal verification value.

| Category | Files |
|----------|-------|
| Empty conformances | EmptyErrorPage, EmptyInlineElement, EmptyLayout, EmptyTagPage |
| Simple enums | ControlSize, LinkRelationship, LinkTarget, NavigationBarVisibility, Role, HighlighterTheme |
| Thin wrappers | AnyInlineElement, DefaultLayout, ControlLabel, InlineGroup, NavigationItemGroup, MetaStyle |
| Protocols + extensions | Defaultable, ErrorPage, LayoutContent, StaticPage, TagPage, NavigationItemConfigurable, Query |
| Config types | ArticleLoader, Attribute+Convenience, InlineStyle, LengthUnit, PublishingRegistration, SyntaxHighlighterConfiguration |
| Modifier | GridColumnWidthModifier |
| Extension | URL-SelectDirectories |

### 2C. Skip (6 files — no logic to test)

| File | Reason |
|------|--------|
| AriaType.swift | Pure enum of 50+ ARIA string constants |
| BorderStyle.swift | Pure enum of 8 style constants |
| ControlLabelStyle.swift | Pure enum of 4 constants |
| Language.swift | Pure enum of 280+ RFC-5646 language codes |
| Typealiases.swift | 6 type aliases |
| ArticlePage.swift | Empty protocol with trivial extension |

---

## Execution Plan

### Phase 1: Quality fixes (1 commit)
Fix all 32 existing test quality issues (5 float, 2 force-try, 22 weak assertions, 3 random).
These are mechanical changes that don't alter test behavior — they make assertions stronger.

### Phase 2: High-value new tests (1 commit per file or logical group)
Write tests for the 10 "Needs Tests" files. Priority order:
1. **Article.swift** — core content pipeline, most complex
2. **Color.swift** — widely used, hex parsing has edge cases
3. **Site.swift** — publishing flow, configuration aggregation
4. **Markup.swift** — string interpolation, used everywhere
5. **PlainDocument.swift** — document rendering
6. **LinkGroup.swift** — privacy-sensitive rendering
7. **DecodeAction.swift** — file I/O, JSON decoding
8. **Event.swift** — ordering, hashing
9. **EmailPlatform.swift** — platform-specific attributes
10. **Material.swift** — CSS class generation

### Phase 3: Low-priority smoke tests (optional, batch commit)
Basic existence/rendering smoke tests for the 30 low-priority files. These verify
that types can be instantiated and produce non-empty markup where applicable.

---

## Success Criteria

- Quality gate `test-quality` checker: **0 errors, 0 warnings**
- All 10 high-value files have test counterparts with meaningful assertions
- All tests pass on CI (Swift 6.0.x compatibility)
- No changes to production source code (test-only branch)
