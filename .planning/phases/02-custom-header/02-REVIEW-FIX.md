---
phase: 02-custom-header
fixed_at: 2026-04-27T00:00:00Z
review_path: .planning/phases/02-custom-header/02-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-04-27
**Source review:** .planning/phases/02-custom-header/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (CR-01, WR-01, WR-02, WR-03, WR-04)
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Unescaped triple-brace renders `fancy_title` HTML without sanitization

**Files modified:** `javascripts/discourse/components/tavern-banner.hbs`, `javascripts/discourse/components/tavern-banner.js`
**Commit:** 5f11666
**Applied fix:** Added `fancyTitle` class field to `TavernBanner` that wraps the API value in `htmlSafe()` (the import was already present). Replaced both `{{{t.fancy_title}}}` (line 17) and `{{{this.featured.fancy_title}}}` (line 36) in the template with `{{this.fancyTitle t}}` and `{{this.fancyTitle this.featured}}` respectively. The `htmlSafe()` call makes the trust contract explicit and prevents stored XSS if server-side sanitization regresses.

### WR-01: i18n mutation is destructive — overwrites the shared translations object in place

**Files modified:** `javascripts/discourse/api-initializers/theme-setup.js`
**Commit:** c4ebec5
**Applied fix:** Added value-equality guards before each of the five translation assignments (`filters.latest.title`, `filters.top.title`, `filters.hot.title`, `filters.categories.title`, `log_in`). Each block now checks whether the target value is already the desired string before writing, making the entire patch idempotent. Hot-reload double-patching and any repeated initializer execution are now no-ops.

### WR-02: Banner visibility SCSS selector has a logic error

**Files modified:** `common/common.scss`
**Commit:** 68502f0
**Applied fix:** Replaced the two-rule block (`:not` chain plus separate `body.archetype-regular` rule) with a single `body:not(.navigation-topics):not(.navigation-categories) .tavern-banner { display: none; }` rule. Topic pages carry neither navigation class and are already hidden by the remaining `:not` chain, so the redundant `archetype-regular` clause was removed. Added a comment explaining the reasoning.

### WR-03: `loadData()` gated on `shouldShow` in constructor — router not yet settled

**Files modified:** `javascripts/discourse/components/tavern-banner.js`
**Commit:** 2981d9a
**Applied fix:** Changed the constructor guard from `if (this.shouldShow) this.loadData()` to `if (settings.show_homepage_banner) this.loadData()`. Data loading is now independent of route-based visibility. `shouldShow` continues to control template rendering reactively; the constructor no longer risks skipping `loadData()` due to `router.currentRouteName` being empty at construction time.

### WR-04: `@outletArgs.title` in connector template may be undefined on some Discourse versions

**Files modified:** `javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs`
**Commit:** 280286e
**Applied fix:** Changed `alt={{@outletArgs.title}}` to `alt={{or @outletArgs.title "Liberty Tavern"}}`. The `or` helper provides a hardcoded fallback so the `alt` attribute is never the string `"undefined"` if the outlet does not pass a `title` arg.

---

_Fixed: 2026-04-27_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
