---
phase: 02-custom-header
plan: "01"
subsystem: header
tags: [connector, scss, logo, header, branding]
dependency_graph:
  requires: []
  provides:
    - home-logo-contents connector rendering tavern logo on every page
    - .d-header SCSS extensions (min-height, login-button, nav-pills states)
    - .tavern-logo BEM class definitions
    - #main-outlet-wrapper padding compensation for fixed header
  affects:
    - common/common.scss
    - javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs
tech_stack:
  added: []
  patterns:
    - Discourse home-logo-contents WRAPPER outlet (HBS-only, no JS)
    - BEM CSS naming (.tavern-logo__image, .tavern-logo__text, etc.)
    - SCSS nesting inside .d-header for scoped button/nav overrides
key_files:
  created:
    - javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs
  modified:
    - common/common.scss
decisions:
  - "Use {{theme-asset \"logo.png\"}} double-curlies (not triple) — value is a URL, not sanitized HTML"
  - "min-height on .d-header only, no display/flex-direction/position — preserves Discourse flex layout for native icons"
  - "padding-top: 64px on #main-outlet-wrapper and #main-outlet — compensates for fixed header so content does not overlap"
metrics:
  duration: "114s (~2 minutes)"
  completed: "2026-04-27"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 2 Plan 01: Home-Logo-Contents Connector and Header SCSS Summary

**One-liner:** Discourse `home-logo-contents` connector with BEM markup plus SCSS extensions delivering the Liberty Tavern logo, brass-styled Sign In button, and 64px header height compensation.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create home-logo-contents connector HBS | ffec477 | javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs (created) |
| 2 | Extend common.scss with logo, login-button, nav, and header-height rules | bab509b | common/common.scss (modified, +81 lines) |

## What Was Built

**Task 1 — `tavern-logo.hbs`**

A HBS-only connector placed at `javascripts/discourse/connectors/home-logo-contents/` that replaces Discourse's default logo rendering on every page. The connector uses:
- `{{theme-asset "logo.png"}}` for the image source (CDN-safe, no injection vector)
- `{{@outletArgs.title}}` for the `alt` attribute (forward-compatible Glimmer outlet syntax)
- BEM class hierarchy: `.tavern-logo` > `.tavern-logo__image`, `.tavern-logo__text` > `.tavern-logo__title`, `.tavern-logo__tagline`
- No `<a>` wrapper — Discourse's `home-logo.gjs` already wraps the outlet in `<a href="/">`
- No companion `.js` file — purely declarative markup

**Task 2 — `common.scss` additions**

Inside the existing `.d-header {}` block:
- `min-height: 64px` — sets header height without overriding Discourse's flex layout
- `.login-button` — brass background, dark text, uppercase, focus-visible outline (`#f5ebd9`), active brightness filter
- `.nav-pills .nav-item.active a` — brass border-bottom underline for active nav tab
- `.nav-pills .nav-item a:focus-visible` — brass outline for keyboard nav
- `.nav-pills .nav-item a` — Inter font, 13px, 700 weight for nav link typography

After `.d-header {}` block (standalone):
- `.tavern-logo` BEM rules: flex layout, 8px gap
- `.tavern-logo__image`: 36px height, auto width, block display
- `.tavern-logo__text`: column flex, centered
- `.tavern-logo__title`: Playfair Display italic 900, 20px, cream `#f5ebd9`
- `.tavern-logo__tagline`: Inter 10px 700 uppercase, cream 70% opacity
- `#main-outlet-wrapper, #main-outlet { padding-top: 64px }` — prevents page content from hiding behind fixed header

## Requirements Delivered

- **HEAD-01**: Logo image visible on every page — connector fires in `.d-header` on all Discourse routes
- **HEAD-02**: "The Liberty Tavern" and "Free Speech · Est. MDCCXCI" appear in header beside logo
- **HEAD-04**: `.login-button` styled with brass background — logged-out visitors see styled Sign In button
- **HEAD-05**: No `display`, `flex-direction`, or `position` overrides on `.d-header` — Discourse's native flex layout for search icon and user-menu icon is preserved intact

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all markup and styles are fully wired. Logo image references `assets/logo.png` via the `theme-asset` helper; the asset file must exist in the theme's `assets/` directory for the image to render. This is a pre-existing asset requirement, not a stub introduced by this plan.

## Threat Flags

None — both files introduce no new network endpoints, auth paths, file access patterns, or schema changes beyond what the plan's threat model documented (T-02-01, T-02-02, both `accept`).

## Self-Check: PASSED

- FOUND: javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs
- FOUND: common/common.scss
- FOUND: .planning/phases/02-custom-header/02-01-SUMMARY.md
- FOUND commit ffec477: feat(02-01): add home-logo-contents connector HBS
- FOUND commit bab509b: feat(02-01): extend common.scss with logo, login-button, nav, and header-height rules
