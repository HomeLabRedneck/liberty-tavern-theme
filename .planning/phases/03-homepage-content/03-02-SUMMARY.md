---
phase: 03-homepage-content
plan: "03-02"
subsystem: ui
tags: [scss, discourse-theme, bem, stats-panel, trending, category-boxes]

# Dependency graph
requires:
  - phase: 03-01
    provides: tavern-banner.gjs template emitting .tavern-banner__stats, .tavern-trending, and updated class names

provides:
  - SCSS for stats panel (.tavern-banner__stats with corner brackets, stat-row, stat-label, stat-num)
  - SCSS for §9 standalone trending strip (.tavern-trending with 3-column grid, ink/oxblood colors)
  - SCSS extensions for §6 room cards (.category-boxes gap, .category-box shadow/radius/hover, .category-box-inner padding)
  - Dead code removed: &__feature, &__feature-link, &__feature-title, &__trending (§8 inner), &__badges

affects:
  - 03-03 (admin checkpoint — categories_boxes DOM verification)
  - 03-04 (honored patrons sidebar if it references banner layout)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "BEM &__modifier siblings at same nesting depth inside .tavern-banner { }"
    - "Corner bracket decoration via ::before/::after absolute-positioned pseudo-elements on position:relative container"
    - "Additive §6 extension pattern — new rules appended after existing block, no mutation of shared selector"
    - "Standalone section (.tavern-trending) as BEM root class outside parent block"

key-files:
  created: []
  modified:
    - common/common.scss

key-decisions:
  - "&__stat-row, &__stat-label, &__stat-num placed as BEM siblings of &__grid at the same nesting depth, not nested inside &__stats — matches existing banner sub-element pattern"
  - "§6 room card extensions inserted before // ---- 7. Buttons comment as additive rules, existing .category-list .category, .category-boxes .category-box shared rule left untouched"
  - "§9 appended after the body:not() hide rule, keeping the file ordered: §8 root → ribbon → sub-elements → hide rule → §9"

patterns-established:
  - "BEM siblings at same depth: all .tavern-banner sub-elements (including new stat elements) nest directly inside .tavern-banner { } at one level deep"
  - "Additive §6 extension: new .category-boxes rules appended after existing §6 block without touching the shared selector"

requirements-completed:
  - STATS-05
  - ROOM-02
  - ROOM-03
  - ROOM-04

# Metrics
duration: 2min
completed: 2026-04-28
---

# Phase 3 Plan 02: SCSS Dead Code Removal + Stats Panel, Trending Strip, Room Card Styles

**Dead §8 SCSS purged and replaced with stats panel (30px italic Playfair brass tabular-nums, corner bracket pseudo-elements), §9 cream trending strip (3-col grid, ink/oxblood), and §6 room card extensions (2px radius, shadow hover lift)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-28T13:50:46Z
- **Completed:** 2026-04-28T13:52:54Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Removed 5 dead BEM blocks from §8 (91 lines of dead code gone): `&__feature`, `&__feature-link`, `&__feature-title`, `&__trending` (inner banner), `&__badges`
- Added stats panel styles inside `.tavern-banner { }`: `&__stats` container (frosted glass, brass border, corner bracket `::before`/`::after`), `&__stat-row` (flex space-between baseline), `&__stat-label` (10px Inter small-caps 0.75 opacity), `&__stat-num` (30px italic Playfair brass tabular-nums), `&__stat-num--loading`
- Added §9 `.tavern-trending` block (cream background, 32px/64px/24px padding, bottom rule, flex header, 3-column grid items with category-color border-top, small-caps cat label, 15px Playfair title with oxblood hover, Spectral italic meta)
- Added §6 `.category-boxes` gap properties, `.category-box` border-radius/shadow/overflow/transition with hover lift, `.category-box-inner` padding, `.category-stat`/`.stat-text` Inter count label styles

## Task Commits

1. **Task 1: Delete 5 dead §8 blocks + add stats panel styles** — `13684ee` (feat)
2. **Task 2: Add §9 trending strip styles + §6 room card extensions** — `44af7f8` (feat)

**Plan metadata:** _(pending final docs commit)_

## Files Created/Modified

- `common/common.scss` — Dead §8 blocks removed; `&__stats`/`&__stat-row`/`&__stat-label`/`&__stat-num` added inside §8; `.tavern-trending` §9 appended; `.category-boxes` §6 extensions inserted

## Decisions Made

- `&__stat-row`, `&__stat-label`, `&__stat-num` are BEM siblings of `&__grid` at the same nesting depth inside `.tavern-banner { }`, not nested inside `&__stats`. This matches the existing sub-element pattern and avoids specificity conflicts.
- §6 extensions placed as additive rules immediately before `// ---- 7. Buttons` comment. The existing shared selector `.category-list .category, .category-boxes .category-box` was not touched.
- §9 appended after the `body:not()` hide rule (end of file) to preserve section ordering: §8 content → hide rule → §9 new section.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All SCSS surfaces are wired and ready for the Plan 03-01 GJS component to render into them
- Plan 03-03 (admin checkpoint: set `desktop_category_page_style` to `categories_boxes`) is next — no SCSS blockers
- `.category-stat` / `.stat-text` selectors may need DOM inspection on a live instance; if Discourse uses a different inner class the count rule has no harmful effect

## Known Stubs

None — this plan is pure SCSS with no template data rendering.

---
*Phase: 03-homepage-content*
*Completed: 2026-04-28*
