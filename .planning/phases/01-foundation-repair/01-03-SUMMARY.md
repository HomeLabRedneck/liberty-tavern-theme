---
plan: 01-03
phase: 01-foundation-repair
status: complete
completed: 2026-04-26
requirements: [FOUND-05, FOUND-06, FOUND-07, FOUND-08]
---

## What Was Built

Fixed sidebar reactivity, eliminated Google Fonts double-load, wired accent_hue admin setting to brass color, and added BEM SCSS classes for the inline styles removed in Plan 02.

## Key Files

### Modified
- `javascripts/discourse/api-initializers/honored-patrons.js` — added `import { tracked }`, replaced `_patrons` instance field + `appEvents.trigger("sidebar:refresh")` with `@tracked patrons = []` and direct assignment; updated `links` getter to use `this.patrons`
- `common/common.scss` — removed `@import url('https://fonts.googleapis.com/...')` (fonts already loaded via `head_tag.html`); changed `--tavern-brass` from hardcoded `#c8941a` to `hsl(#{$accent_hue}, 68%, 45%)`; added `&__feature-link` and `&__feature-title` BEM blocks inside `.tavern-banner` scope

## Decisions Made

- `appEvents.trigger("sidebar:refresh")` removed entirely — that event doesn't exist in Discourse; `@tracked` auto-rerenders on assignment
- `hsl` values `68%, 45%` preserved from original color; admin shifts only hue

## Self-Check: PASSED

- [x] `honored-patrons.js` has `@tracked patrons = []`
- [x] No `_patrons`, `appEvents`, `sidebar:refresh`, or `api.container` in honored-patrons.js
- [x] `common.scss` has no `@import googleapis`
- [x] `--tavern-brass: hsl(#{$accent_hue}, 68%, 45%)` present
- [x] `&__feature-link` and `&__feature-title` BEM blocks inside `.tavern-banner`
- [x] All changes committed
