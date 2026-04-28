# Roadmap: Liberty Tavern Discourse Theme

**Created:** 2026-04-26
**Granularity:** Coarse
**Mode:** YOLO
**Total Phases:** 4
**Coverage:** 26/26 v1 requirements mapped

## Project Goal

Repair and complete the Liberty Tavern Discourse theme so the homepage matches the Image 1 design target — custom header bar, styled banner with live stats, trending strip, room cards, and a right-column rail with badges and house rules.

## Phases

- [x] **Phase 1: Foundation Repair** — Fix the broken/duplicated banner, kill 404 CTA, stabilize sidebar reactivity, clean up font and styling debt *(completed 2026-04-26)*
- [x] **Phase 2: Custom Header** — Mount the tavern header (logo, title, tagline, nav links, Sign In) on every page *(completed 2026-04-27)*
- [x] **Phase 3: Homepage Content** — Wire live stats panel and render the Rooms section as styled category cards *(completed 2026-04-28)*
- [ ] **Phase 4: Right Column** — Add the two-column homepage layout with Badges and House Rules panels

## Phase Details

### Phase 1: Foundation Repair
**Goal**: Eliminate the visible bugs blocking everything else — banner duplication, 404 CTA, flaky sidebar, font/styling debt — so the homepage banner renders correctly once and the codebase is stable enough to build on.
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06, FOUND-07, FOUND-08
**Success Criteria** (what must be TRUE):
  1. Banner appears exactly once on the homepage, above the topic list, with full SCSS styling applied (no plain-text duplicate at the top of the page).
  2. Clicking "Pull a Stool" opens the Discourse new-topic composer for logged-in users (and routes anonymous users to login) — never returns 404.
  3. Honored Patrons sidebar section populates patron avatars on first load, including on slow connections, without depending on the undocumented `sidebar:refresh` event.
  4. Google Fonts load exactly once per page (verified by checking network tab for a single Playfair/Spectral/Inter request) and the `accent_hue` admin setting visibly changes the brass accent color.
**Plans**: 4 plans

Plans:
- [x] 01-01-PLAN.md — Banner outlet fix: create theme-setup.js with api.renderInOutlet, disable WelcomeBanner in about.json, delete connector file
- [x] 01-02-PLAN.md — CTA + inline styles: fix /new-topic 404 with composer action, remove inline style= from banner template
- [x] 01-03-PLAN.md — SCSS cleanup: fix sidebar @tracked reactivity, remove Google Fonts @import, wire accent_hue to --tavern-brass, add BEM classes
- [x] 01-04-PLAN.md — UAT fixes: honored_patrons_group empty default + guard, all #c8941a → var(--tavern-brass), eyebrow text, sidebar background

### Phase 2: Custom Header
**Goal**: Replace Discourse's default header chrome with the tavern header bar shown in Image 1, while preserving native search and user-menu functionality.
**Depends on**: Phase 1
**Requirements**: HEAD-01, HEAD-02, HEAD-03, HEAD-04, HEAD-05
**Success Criteria** (what must be TRUE):
  1. Every page (homepage, topic, category, profile) shows the Liberty Tavern logo plus "The Liberty Tavern" title and "Free Speech · Est. MDCCXCI" tagline in the header.
  2. Header navigation displays the four links — Trending, Rooms, Latest at the Bar, Top Shelf — and each link routes to the expected Discourse view.
  3. Anonymous (logged-out) visitors see a Sign In button in the header that opens the Discourse login modal.
  4. Native search icon and user-menu still open and function correctly (not hidden, not broken by custom header CSS).
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md — Logo connector + SCSS: home-logo-contents HBS connector, login-button styling, nav active/focus states, header min-height 64px
- [x] 02-02-PLAN.md — Nav label i18n patch + admin setup: JS I18n.translations patch for Trending/Rooms/Latest at the Bar/Top Shelf/Sign In; top_menu admin step documented

### Phase 3: Homepage Content
**Goal**: Make the banner show real live numbers and turn the homepage category list into the styled "Rooms" cards from Image 1.
**Depends on**: Phase 1, Phase 2
**Requirements**: STATS-01, STATS-02, STATS-03, STATS-04, STATS-05, ROOM-01, ROOM-02, ROOM-03, ROOM-04
**Success Criteria** (what must be TRUE):
  1. Stats panel shows non-zero numeric values for Members, Posts Today, Open Rooms, and Patrons Inside, sourced from `/about.json` on page load.
  2. Stats numbers render in italic Playfair Display in the brass/gold color (matching Image 1) — not plain default text.
  3. Homepage categories render as a grid of styled cards with colored category icon, name, description, topic count, and post count visible on each card.
  4. Rooms cards visually match Image 1 — cream card background, category color accent, consistent card spacing.
**Plans**: 3 plans

Plans:
- [x] 03-01-PLAN.md — Banner JS + template: Promise.all data loading, stats panel in aside, trending sibling outside banner, toItem enrichment, dead code removal
- [x] 03-02-PLAN.md — SCSS: delete 5 dead §8 blocks, add stats panel styles, add §9 trending section, extend §6 room cards
- [x] 03-03-PLAN.md — Admin step: set desktop_category_page_style to categories_boxes (manual, blocking checkpoint)

### Phase 4: Right Column
**Goal**: Add a right-column rail beside the homepage main content with Badges and House Rules panels, hiding cleanly on narrow screens.
**Depends on**: Phase 1, Phase 2, Phase 3
**Requirements**: COL-01, COL-02, COL-03, COL-04
**Success Criteria** (what must be TRUE):
  1. On screens 1160px wide or wider, a right-column rail appears beside the homepage main content (not below it, not overlapping).
  2. On screens narrower than 1160px, the right column is hidden and main content fills the width without broken layout or horizontal scroll.
  3. Badges panel shows a styled grid of popular badges with badge icon and grant count visible on each entry.
  4. House Rules panel shows the four house rules as a styled, readable list.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation Repair | 4/4 | Complete | 2026-04-26 |
| 2. Custom Header | 2/2 | Complete | 2026-04-27 |
| 3. Homepage Content | 3/3 | Complete | 2026-04-28 |
| 4. Right Column | 0/0 | Not started | - |

## Coverage Validation

All 26 v1 requirements are mapped to exactly one phase. No orphans, no duplicates.

| Phase | Requirement Count | Requirements |
|-------|-------------------|--------------|
| 1 | 8 | FOUND-01..08 |
| 2 | 5 | HEAD-01..05 |
| 3 | 9 | STATS-01..05, ROOM-01..04 |
| 4 | 4 | COL-01..04 |
| **Total** | **26** | **26/26** |

---
*Roadmap created: 2026-04-26*
*Phase 1 plans created: 2026-04-26*
*Phase 2 plans created: 2026-04-27*
*Phase 3 plans created: 2026-04-28*
