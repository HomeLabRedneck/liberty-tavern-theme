---
plan: 04-02
phase: 04-right-column
type: checkpoint:human-verify
status: complete
verified_live: 2026-08-29
commits:
  - a8698ca  # rail mount → #list-area grid (match mockup)
  - 08859be  # topic-list overflow-into-rail fix
---

# 04-02 — Right Column: Live Verification (checkpoint:human-verify)

Plan 04-01 built the rail against ASSUMED selectors. This plan verified it on the
live Discourse instance (theme id 15, preview) and fixed what the real DOM proved wrong.

## What 04-01 got wrong (found live, fixed here)

1. **Mount point.** `after-main-outlet` does NOT render inside `#main-outlet` on this
   Discourse version — it renders at the OUTER `.wrap` (a sibling of `.sidebar-wrapper`
   and the main content column). Gridding `#main-outlet` therefore scattered Discourse's
   many containers into alternating grid cells → squished, overflowing layout.
   **Fix (a8698ca):** convert the rail from a connector to a component rendered via
   `api.renderInOutlet("discovery-list-container-top", TavernRightColumn)` in
   `theme-setup.js` (the same outlet the banner uses) so it lands as a direct child of
   `#list-area`. Grid `#list-area` with named areas — banner + trending span both columns,
   `.contents` (the list) in col 1, rail in col 2. DOM order is irrelevant. Deleted the
   `connectors/after-main-outlet/tavern-right-column.gjs`; added
   `components/tavern-right-column.gjs`.

2. **Topic-list overflow into the rail.** On `/latest`, `/top`, trending the `.topic-list`
   table inherited the §2 full-width rule (`width:100%` + `margin-left:64px`), overflowing
   its grid column by 64px and drawing under the Badges rail.
   **Fix (08859be):** re-anchor with `#list-area` specificity —
   `width: calc(100% - 64px); margin-right:0` — so the table ends at the column edge,
   leaving the 32px gutter. `.topic-list-bottom` pinned to column 1.

## Design decision confirmed with the user (mid-verification)

The rail-beside-whole-column layout (banner narrowed) was rejected; the user chose the
**mockup-exact** layout: banner + trending full-width across the top, rail below-right
beside the Rooms/topic list. That is what shipped.

## Live verification results (deployed code, no injection)

| Requirement | View(s) | Result |
|-------------|---------|--------|
| COL-01 rail beside main ≥1160px | Rooms (categories), Latest, Top, Trending | ✓ rail in `#list-area` grid col 2, 280px, 32px gutter |
| COL-02 hidden <1160px, no scroll | Rooms @1050px | ✓ `#list-area` reverts to block, rail `display:none`, main reflows; no element exceeds viewport (the 5px `scrollWidth−clientWidth` is the vertical scrollbar, not real overflow) |
| COL-03 Badges 2×2 top-4 | all | ✓ real `/badges.json` top-4 by grant_count: BASIC 38, WELCOME 34, FIRST LIKE 33, EDITOR 30; tier-colored clip-path hexagons |
| COL-04 House Rules list | all | ✓ oxblood box, 4 rules from `settings.house_rules` |
| No topic-list overlap | Latest, Top | ✓ 32px gap (was −32px overlap) |
| Full-width banner + rail below (mockup) | Rooms | ✓ banner/trending span, rail below-right |

## Out of scope for Phase 4 — flagged for follow-up

- **Header nav row** does NOT match the mockup (shows `Latest / New (17) / Top / Categories`;
  mockup wants `Trending / Rooms / Latest at the Bar / Top Shelf`). This is Phase 2 (HEAD-*),
  not COL-*: (1) the theme-setup.js i18n rename is not taking effect on this install,
  (2) `top_menu` is `latest|new|unread|hot|top|categories` (global site setting) and needs to
  be `hot|categories|latest|top`, (3) the `hot`/Trending pill is currently hidden by §2b CSS
  (a Phase 3 decision the mockup reverses). Tracked separately.
- **Banner + trending show on all discovery views**; the mockup shows them only on Rooms.
  Pre-existing banner `shouldShow` behavior (Phase 1/3), not COL-*. Flagged.

## Artifacts this phase produced
- `javascripts/discourse/components/tavern-right-column.gjs` (TavernRightColumn, tierClass)
- `theme-setup.js` renderInOutlet mount for the rail
- `common/common.scss` §10: `#list-area` named grid + `.tavern-badges*` / `.tavern-house-rules*` + responsive hide
- `settings.yml`: `show_right_column`, `house_rules`
- (removed) `connectors/after-main-outlet/tavern-right-column.gjs`
