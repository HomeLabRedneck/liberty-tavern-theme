---
phase: 04-right-column
plan: 01
subsystem: homepage-right-column
status: complete
tags: [discourse-theme, scss-grid, glimmer-connector, badges, right-column]
requires:
  - "common/common.scss :root tokens (ink/cream/oxblood/brass/rule) + fonts from head_tag.html"
  - "/badges.json (public, unauthenticated Discourse endpoint)"
provides:
  - "TavernRightColumn connector (after-main-outlet) — Badges + House Rules rail"
  - "settings show_right_column (bool) + house_rules (list)"
  - "common.scss section 10 (grid override + rail + badges + house-rules + <1160px reset)"
affects:
  - "#main-outlet grid layout on discovery views (body.navigation-categories/topics) — highest blast radius in project"
tech-stack:
  added: []
  patterns:
    - "Connector-as-component (.gjs under connectors/<outlet>/) auto-mounts — mirrors tavern-room-preview.gjs"
    - "Data-fetch: @service router + @tracked + constructor-gated loadBadges() + ajax().catch(()=>null) + console.warn + finally loading=false — mirrors tavern-banner.gjs"
    - "module-scope tierClass() helper in GJS template scope — mirrors timeAgo() pattern"
    - "Flat BEM selectors in section 10 (not &__ nesting) for source-level greppability"
key-files:
  created:
    - javascripts/discourse/connectors/after-main-outlet/tavern-right-column.gjs
  modified:
    - common/common.scss
    - settings.yml
decisions:
  - "Grid container: #main-outlet (scoped to body.navigation-categories/body.navigation-topics) — reuses the already-proven discovery wrapper from lines 139-149"
  - "Mount strategy: PRIMARY after-main-outlet connector (auto-mounts, renders as last child of #main-outlet); FALLBACK renderInOutlet documented in .gjs + scss comments for plan 04-02 to resolve live"
  - "Section 10 uses flat BEM selectors so plan's grep-based acceptance passes; compiles identically to §8/§9 nested form"
metrics:
  duration: "~15m"
  completed: 2026-08-29
actuals:
  tokens: 6500
  tasks: 3
  commits: 3
---

# Phase 4 Plan 1: Right-Column Rail (Badges + House Rules) Summary

Homepage right-column rail — a `TavernRightColumn` connector at `after-main-outlet` that fetches `/badges.json` (top-4 by grant_count as a 2×2 tier-hexagon grid) and renders the four locked House Rules, placed beside the discovery content via a `#main-outlet` CSS-grid override at ≥1160px and hidden below.

## Chosen grid container + mount strategy (for plan 04-02 live verification)

- **Grid container selector:** `#main-outlet`, scoped under `body.navigation-categories, body.navigation-topics`. Chosen because lines 139-149 already treat `#main-outlet` as the discovery content wrapper (full-width overrides proven live in Phase 3). The `@media (min-width: 1160px)` block sets `display: grid; grid-template-columns: minmax(0, 1fr) 280px; column-gap: 32px; align-items: start`.
- **Full-width span:** `[data-outlet="discovery-list-container-top"]` (banner outlet) and `.tavern-trending` get `grid-column: 1 / -1` so the banner + stats box + trending strip keep the full content width (D-1). `.tavern-right-column` sits in `grid-column: 2`.
- **Mount strategy — PRIMARY:** `after-main-outlet` connector (`connectors/after-main-outlet/tavern-right-column.gjs`) auto-mounts; Discourse renders it as the last child of `#main-outlet`, making it a grid sibling of the list-container.
- **Mount strategy — FALLBACK (documented, not applied):** if plan 04-02 DevTools shows `after-main-outlet` renders OUTSIDE `#main-outlet` (so it can't be a grid sibling while the banner stays full-width), switch to `api.renderInOutlet(<inside-#main-outlet discovery outlet>, TavernRightColumn)` in `theme-setup.js` (guarded by `settings.show_right_column`) and grid that inner wrapper. The 280px / 32px / 1160px contract holds either way. `theme-setup.js` was NOT modified — the connector auto-mount made it unnecessary for the primary path.

**LIVE-VERIFY items left for plan 04-02:** (1) confirm `after-main-outlet` renders inside `#main-outlet` on this Discourse version; (2) confirm the connector mounts on `.topic-list` views (Trending/Latest/Top), not only `.category-boxes` (Rooms) — the component's own `/^discovery\./` route gate + SCSS body-class scoping are what constrain it to the four views, but the DOM position relative to `#main-outlet` must be confirmed live.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | End-to-end rail: mount, grid override, badge data, house rules | ad5adc9 | tavern-right-column.gjs, common.scss, settings.yml |
| 2 (auto) | Badges panel visual treatment — hex tiles + tier colors | 1a11320 | common.scss, tavern-right-column.gjs |
| 3 (auto) | House Rules styling + <1160px responsive hide/reflow | 14eb94d | common.scss |

## What was built

- **`TavernRightColumn` connector** (`after-main-outlet/tavern-right-column.gjs`): `@service router`, `@tracked badges/loading`; `shouldShow` (settings gate + `/^discovery\./` route gate), `houseRules` (split `settings.house_rules` on `|`), `hasBadges`. `loadBadges()` fetches `/badges.json`, sorts a copy by `grant_count` desc, `slice(0,4)`, maps to `{name,count,typeId,icon,imageUrl}`; `console.warn` on error; `loading=false` in `finally`. Panel only renders `{{#if this.hasBadges}}{{#unless this.loading}}` (hidden on zero/error — UI-SPEC empty/error states). House Rules block is static, always rendered.
- **Badges panel** (§10): Playfair-italic-900 "Badges" header with oxblood hairline + short brass `::after` segment; 2×2 grid; `#E8DCC0` tiles with `var(--tavern-rule)` border; `clip-path` hexagons with `--gold`/`--silver`/`--bronze` tier fills mapped from `badge_type_id` via `tierClass()`; uppercase Inter name (wraps via `overflow-wrap: anywhere` — overflow backstop); muted tabular-nums `{N} EARNED` count.
- **House Rules panel** (§10): oxblood-bordered cream box (14px padding, locked), uppercase oxblood eyebrow with brass `::before` tick, decimal Spectral `<ol>` (13px, line-height 1.7).
- **Responsive reset** (§10): `@media (max-width: 1159.98px)` scoped to discovery body classes collapses `#main-outlet` to `display: block` and hides `.tavern-right-column` — no phantom track, no horizontal scroll.
- **Settings:** `show_right_column` (bool, default true) + `house_rules` (list, 4 D-4 defaults pipe-joined).

## Security (threat model)

- **T-04-01 (badge name XSS):** mitigated — `{{b.name}}` plain interpolation, Glimmer auto-escapes; never `htmlSafe`.
- **T-04-02 (badge image_url XSS):** mitigated — `image_url` bound only to `<img src>`, never raw HTML.
- **T-04-05 (house_rules render):** `{{rule}}` auto-escaped; admin-trusted setting.

## Deviations from Plan

### [Rule 3 - Blocking] Flat BEM selectors in section 10 instead of `&__` nesting
- **Found during:** Task 2
- **Issue:** The plan's automated `<verify>` greps for literal flat class names (`tavern-badges__tile`, `tavern-badges__hex--gold`, `tavern-house-rules__eyebrow`, etc.). The existing §8/§9 convention uses `&__` SCSS nesting under a parent block, so those literal strings never appear in source and the greps failed.
- **Fix:** Wrote section 10's new BEM elements as flat selectors (`.tavern-badges__tile { }`, `.tavern-badges__hex--gold { }`, etc.). Compiles to identical CSS; makes the acceptance greps pass. `.tavern-right-column` was already flat (Task 1 verify passed).
- **Files modified:** common/common.scss
- **Commits:** 1a11320, 14eb94d

### [Rule 1 - Verify command bug] Plan's `list-style` grep is malformed
- **Found during:** Task 3
- **Issue:** Plan verify uses `grep -q "list-style: ?decimal\|..."` without `-E`. In BRE, `?` is a literal `?` (not "optional space"), making the pattern unsatisfiable by any valid CSS `list-style: decimal` declaration.
- **Fix:** Source is correct valid CSS (`list-style: decimal`); confirmed intent met with the corrected `grep -E "list-style: ?decimal"`. No code change — the verify command, not the code, is at fault. Documented so plan 04-02 / future greps use `-E` or `\?`.
- **Files modified:** none (code was already correct)

## Known Stubs

None. All data is live (`/badges.json`) or from admin-editable settings (`house_rules`).

## Verification

- Task 1 (`TRACER_OK`), Task 2 (`BADGES_OK`), Task 3 (`HOUSERULES_OK` with corrected `-E` on the list-style grep) all pass source-level.
- No inline `style=` in the `.gjs` (0), no `@import` in SCSS (0), reuses `:root` vars throughout (45 `var(--tavern*` usages in file).
- **Live visual verification is explicitly deferred to plan 04-02** (this executor has no browser access, per orchestrator instruction). The tracer's live `<human-check>` (rail beside cards, banner full-width, real badge data) is part of 04-02's cross-view + DevTools selector confirmation.

## Self-Check: PASSED
- FOUND: javascripts/discourse/connectors/after-main-outlet/tavern-right-column.gjs
- FOUND: common/common.scss section 10
- FOUND: settings.yml show_right_column + house_rules
- FOUND commits: ad5adc9, 1a11320, 14eb94d
