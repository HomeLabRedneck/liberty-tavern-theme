---
phase: 02-custom-header
plan: 02
subsystem: ui
tags: [discourse, i18n, glimmer, api-initializer, nav-pills, translations]

# Dependency graph
requires:
  - phase: 01-foundation-repair
    provides: theme-setup.js api-initializer wiring with banner renderInOutlet
provides:
  - i18n patch in theme-setup.js renaming four nav pills and Sign In button label
affects: [02-custom-header, 03-homepage-content]

# Tech tracking
tech-stack:
  added: [discourse-i18n (import pattern from discourse-i18n)]
  patterns: [client-side i18n.translations mutation for English-only theme overrides]

key-files:
  created: []
  modified:
    - javascripts/discourse/api-initializers/theme-setup.js

key-decisions:
  - "JS api-initializer patch used instead of locales/en.yml — theme locale namespace cannot override js.* core strings"
  - "filters.latest.title assigned as pluralized object {zero, one, other} — NOT a plain string — avoids missing-translation console error"
  - "top_menu site setting documented as required one-time admin step (not themeable via about.json)"
  - "show_homepage_banner guard moved to wrap only the renderInOutlet call so i18n patch runs unconditionally"

patterns-established:
  - "i18n patch pattern: import { i18n } from 'discourse-i18n'; mutate i18n.translations[locale].js directly"
  - "Pluralized translation keys must be assigned objects not strings"

requirements-completed:
  - HEAD-03
  - HEAD-04

# Metrics
duration: 8min
completed: 2026-04-27
---

# Phase 2 Plan 02: i18n Nav Pill and Sign In Label Patch Summary

**Client-side i18n.translations mutation renaming Discourse nav pills to Trending/Rooms/Latest at the Bar/Top Shelf and the login button to Sign In**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-27T00:00:00Z
- **Completed:** 2026-04-27T00:08:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Rewrote `theme-setup.js` to import `{ i18n }` from `discourse-i18n` and mutate the client-side translations store
- Patched `filters.latest.title` as a pluralized object `{zero, one, other}` to avoid `[missing translation]` console errors
- Patched `filters.top.title` → "Top Shelf", `filters.hot.title` → "Trending", `filters.categories.title` → "Rooms"
- Patched `translations.js.log_in` → "Sign In" for the header login button
- Preserved Phase 1 banner wiring (`api.renderInOutlet`) with guard scoped only to `show_homepage_banner`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add i18n patch to theme-setup.js for nav labels and Sign In text** - `40b9bf0` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `javascripts/discourse/api-initializers/theme-setup.js` - Added `discourse-i18n` import and i18n translations mutation block; moved `show_homepage_banner` guard to wrap only `renderInOutlet`

## Decisions Made
- Used JS api-initializer patch (not `locales/en.yml`) because theme locale namespace is isolated from the `js.*` core string namespace — the YAML approach was researched and rejected (D-02 correction applied)
- Assigned `filters.latest.title` as a pluralized object rather than a plain string; Discourse's nav-item.js pluralizes this key and a plain string causes a `[missing "en.filters.latest.title" translation]` console error
- Documented `top_menu` site setting change (`hot|latest|categories|top`) as a required one-time admin step in the plan's `user_setup` frontmatter — this setting lacks `themeable: true` and cannot be overridden by a theme

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. The `.planning/phases/02-custom-header/02-RESEARCH.md` file was listed as untracked in the main repo's git status but did not exist in this worktree — all required technical information was present in the plan's `<interfaces>` block and the `<plan_summary>` context, so execution was not blocked.

## User Setup Required

**One-time admin setting change required before nav pills display correctly:**

1. Go to Admin → Settings → search "top menu"
2. Set value to: `hot|latest|categories|top`
3. Save

Without this change, the Trending (`/hot`) nav pill will not appear even after the theme is updated, because `top_menu` is a site-level setting that controls which nav items Discourse renders. The i18n patch renames existing items — it cannot make a hidden item appear.

Verify `hot` is available in your Discourse instance's allowed choices dropdown (it is included by default since Discourse 2.8+).

## Next Phase Readiness
- Plan 02-01 (logo connector + SCSS + sign-in button styling) runs in the same wave — its commits land on the worktree branch independently
- After wave merge, Phase 2 header work is complete: logo area, nav labels, Sign In styling all delivered
- Phase 3 (Homepage Content) can begin once Phase 2 is merged to main

## Self-Check: PASSED

- `javascripts/discourse/api-initializers/theme-setup.js` — FOUND
- `.planning/phases/02-custom-header/02-02-SUMMARY.md` — FOUND
- Commit `40b9bf0` — FOUND

---
*Phase: 02-custom-header*
*Completed: 2026-04-27*
