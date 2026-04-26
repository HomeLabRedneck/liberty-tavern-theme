# Requirements: Liberty Tavern Theme

**Defined:** 2026-04-26
**Core Value:** The homepage must look and function like the Image 1 design — custom header, styled banner with live stats, trending section, and room cards.

## v1 Requirements

### Foundation

- [ ] **FOUND-01**: Banner renders exactly once on the homepage, above the topic list, with full styling applied
- [ ] **FOUND-02**: Discourse's native WelcomeBanner disabled so it does not conflict with our banner
- [ ] **FOUND-03**: Banner mount moved from `below-site-header` outlet to `discovery-list-container-top` via `api.renderInOutlet()` in an api-initializer
- [ ] **FOUND-04**: "Pull a Stool" CTA button opens the Discourse new-topic composer instead of navigating to `/new-topic` (which returns 404)
- [ ] **FOUND-05**: Honored Patrons sidebar section populates reliably on slow connections using `@tracked` reactivity (not the undocumented `sidebar:refresh` event)
- [ ] **FOUND-06**: Google Fonts loaded exactly once — `@import` removed from `common/common.scss`, `<link>` in `head_tag.html` kept
- [ ] **FOUND-07**: Inline `style="..."` attributes removed from `tavern-banner.hbs`; moved to SCSS classes
- [ ] **FOUND-08**: `accent_hue` theme setting wired to `--tavern-brass` CSS variable so admin color changes take effect

### Header

- [ ] **HEAD-01**: Custom header displays the Liberty Tavern logo on every page
- [ ] **HEAD-02**: Header displays site title "The Liberty Tavern" and tagline "Free Speech · Est. MDCCXCI"
- [ ] **HEAD-03**: Header displays navigation links: Trending, Rooms, Latest at the Bar, Top Shelf
- [ ] **HEAD-04**: Header displays Sign In button for anonymous (logged-out) users
- [ ] **HEAD-05**: Discourse's native search and user-menu buttons remain functional in the header

### Stats Panel

- [ ] **STATS-01**: Stats panel shows live Members count (total registered users from `/about.json`)
- [ ] **STATS-02**: Stats panel shows live Posts Today count from `/about.json`
- [ ] **STATS-03**: Stats panel shows live Open Rooms count (active categories count from `/about.json`)
- [ ] **STATS-04**: Stats panel shows Patrons Inside count (`active_users_last_day` from `/about.json` as proxy — no real-time unauthenticated endpoint exists)
- [ ] **STATS-05**: Stats numbers styled with italic Playfair Display in brass/gold color matching Image 1

### Rooms

- [ ] **ROOM-01**: Homepage categories section renders as styled cards (using Discourse's `categories_boxes` page style)
- [ ] **ROOM-02**: Each room card shows colored category icon, category name, and description
- [ ] **ROOM-03**: Each room card shows topic count and post count
- [ ] **ROOM-04**: Room cards styled to match Image 1 (cream background, category color accents)

### Right Column

- [ ] **COL-01**: Right-column panel renders beside main content on wide screens (≥1160px)
- [ ] **COL-02**: Right-column panel hides on narrow screens (no broken layout on mobile/tablet)
- [ ] **COL-03**: Badges panel shows popular badges as a styled grid with badge icon and grant count
- [ ] **COL-04**: House Rules panel shows the 4 house rules as a styled list

## v2 Requirements

### Performance & Polish

- **PERF-01**: Banner data (trending, badges, stats) cached with 5-minute TTL to reduce repeat API calls
- **PERF-02**: `/top.json` and `/badges.json` and `/about.json` fetched in parallel (not sequentially)
- **POLISH-01**: Hardcoded strings in `tavern-banner.hbs` replaced with I18n keys from `locales/en.yml`
- **POLISH-02**: `about.json` `about_url` and `license_url` updated to real repository URL
- **POLISH-03**: "Recent Badges Awarded" label renamed to "Most Awarded Badges" to match what `/badges.json` actually returns (badge popularity, not recent grants)
- **POLISH-04**: `README.md` corrected to document `/badges.json` instead of `/user-badges.json`

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mobile-specific custom layouts | Discourse handles responsively; custom grid applies only on wide screens |
| Internationalization / translations | English-only community; i18n system already in place but not a priority |
| Automated tests | Discourse theme tooling has no test framework; visual verification is manual |
| New features beyond Image 1 | User explicitly scoped to match the design target only |
| Real-time "who's online" count | No public unauthenticated endpoint; requires the `discourse-presence` plugin |
| Discourse plugin development | Everything in scope is achievable as a pure theme |

## Traceability

Phase assignments finalized 2026-04-26 via roadmap creation. Locked.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Pending |
| FOUND-02 | Phase 1 | Pending |
| FOUND-03 | Phase 1 | Pending |
| FOUND-04 | Phase 1 | Pending |
| FOUND-05 | Phase 1 | Pending |
| FOUND-06 | Phase 1 | Pending |
| FOUND-07 | Phase 1 | Pending |
| FOUND-08 | Phase 1 | Pending |
| HEAD-01 | Phase 2 | Pending |
| HEAD-02 | Phase 2 | Pending |
| HEAD-03 | Phase 2 | Pending |
| HEAD-04 | Phase 2 | Pending |
| HEAD-05 | Phase 2 | Pending |
| STATS-01 | Phase 3 | Pending |
| STATS-02 | Phase 3 | Pending |
| STATS-03 | Phase 3 | Pending |
| STATS-04 | Phase 3 | Pending |
| STATS-05 | Phase 3 | Pending |
| ROOM-01 | Phase 3 | Pending |
| ROOM-02 | Phase 3 | Pending |
| ROOM-03 | Phase 3 | Pending |
| ROOM-04 | Phase 3 | Pending |
| COL-01 | Phase 4 | Pending |
| COL-02 | Phase 4 | Pending |
| COL-03 | Phase 4 | Pending |
| COL-04 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 26 total
- Mapped to phases: 26
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-26*
*Last updated: 2026-04-26 — phase assignments finalized in ROADMAP.md*
