---
phase: 01-foundation-repair
plan: 04
subsystem: ui
tags: [scss, discourse-theme, sidebar, accent-color, css-variables]

# Dependency graph
requires:
  - phase: 01-foundation-repair plan 03
    provides: honored-patrons.js with @tracked patrons field and fixed reactivity
provides:
  - honored_patrons_group default empty — sidebar hidden until admin configures a real group
  - Early-return guard in honored-patrons.js — no API call made when group is unconfigured
  - All brass color elements wired to var(--tavern-brass) / accent_hue setting
  - Banner eyebrow text reads "✦ WELCOME, FRIEND ✦"
  - Sidebar background uses var(--tavern-cream) instead of dark --secondary-low
affects: [02-custom-header, 03-homepage-content, 04-right-column]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CSS custom property pattern: var(--tavern-brass) sourced from hsl(#{$accent_hue}, 68%, 45%) in :root — all theme color variations driven by a single settings.yml integer"
    - "filter: brightness(1.15) for hover brightening on elements using CSS custom properties (lighten() cannot operate on runtime values)"

key-files:
  created: []
  modified:
    - settings.yml
    - javascripts/discourse/api-initializers/honored-patrons.js
    - common/common.scss

key-decisions:
  - "D-02: honored_patrons_group default changed to empty string — section hidden by default; admin must explicitly configure a visible group"
  - "D-04: Banner eyebrow changed from '★ A NIGHTLY PRIMER ★' to '✦ WELCOME, FRIEND ✦' — matches design intent"
  - "D-05: Sidebar background changed from var(--secondary-low) to var(--tavern-cream) — --secondary-low resolved to dark charcoal on this Discourse install"
  - "filter: brightness(1.15) chosen over lighten() for hover states because CSS custom properties are runtime values and SCSS lighten() only works on compile-time color literals"

patterns-established:
  - "Sidebar guard pattern: check settings before any API call; return early if not configured"
  - "All theme accent colors reference var(--tavern-brass) — changing accent_hue in Admin propagates everywhere"

requirements-completed: [FOUND-05, FOUND-08]

# Metrics
duration: 2min
completed: 2026-04-26
---

# Phase 1 Plan 04: Foundation Repair UAT Fixes Summary

**Four UAT-identified regressions closed: empty Patrons default with API guard, full accent_hue wiring across 12 hardcoded brass values, correct eyebrow text, and warm cream sidebar background**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-26T07:48:59Z
- **Completed:** 2026-04-26T07:51:19Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Honored Patrons sidebar is now hidden (not broken) by default — no 403 console errors for unauthenticated visitors; admin configures a real group to enable
- All 12 hardcoded `#c8941a` values in common.scss replaced with `var(--tavern-brass)` — changing `accent_hue` in Admin now shifts header border, CTA button, trending prefix, badge icons, and feature card label simultaneously
- Two `lighten(#c8941a, 6%)` hover states replaced with `filter: brightness(1.15)` — hover brightening now also responds to accent_hue at runtime
- Banner eyebrow reads "✦ WELCOME, FRIEND ✦" as per design (was "★ A NIGHTLY PRIMER ★")
- Left sidebar background resolves to warm cream `#f5ebd9` via `--tavern-cream` on all Discourse color schemes (was resolving to dark charcoal via `--secondary-low`)

## Task Commits

1. **Task 1: Honored Patrons 403 — empty default + guard** - `d1a3fdc` (fix)
2. **Task 2: Wire accent_hue — replace all hardcoded #c8941a** - `52d20e2` (fix)
3. **Task 3: CSS text fixes — eyebrow text and sidebar background** - `dfb9e3b` (fix)

## Files Created/Modified

- `settings.yml` — honored_patrons_group default changed from "trust_level_4" to ""; description updated
- `javascripts/discourse/api-initializers/honored-patrons.js` — removed `|| "trust_level_4"` fallback; added `if (!groupName) return;` guard at initializer entry
- `common/common.scss` — 10 static #c8941a → var(--tavern-brass); 2 lighten() hovers → filter: brightness(1.15); eyebrow content updated; sidebar background updated

## Decisions Made

- Used `filter: brightness(1.15)` for hover states rather than a precomputed HSL value — keeps hover visually consistent with whatever hue the admin has set via `accent_hue`, at the cost of brightening text along with background (acceptable for these button/CTA elements)
- No fallback value added to `var(--tavern-cream)` — `--tavern-cream` is defined unconditionally in `:root` at line 15 of the same file, making a fallback redundant

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**Admin configuration required to enable Honored Patrons sidebar:**
1. Go to Admin → Groups → New Group. Set Name (e.g. `honored_patrons`), Visibility: Everyone, Members visibility: Everyone.
2. Add desired users to the group.
3. Go to Admin → Customize → Themes → Liberty Tavern → Settings. Set `honored_patrons_group` to `honored_patrons`.

The sidebar section will not appear until these steps are completed — this is intentional (avoids the 403 that was occurring with the previous "trust_level_4" default on a forum where that system group is not publicly visible).

## Next Phase Readiness

- Phase 1 (Foundation Repair) is fully complete — all 4 UAT issues (Tests 5–8) resolved
- Phase 2 (Custom Header) can begin: `home-logo-contents` outlet, `api.headerIcons.add()`, nav pill components
- No blockers

---

*Phase: 01-foundation-repair*
*Completed: 2026-04-26*
