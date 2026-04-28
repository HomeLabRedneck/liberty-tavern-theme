# Phase 3: Homepage Content — Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire live stats into the banner aside and make the homepage category list render as styled cards. Two deliverables: (1) replace the banner's current "Project of the Night" aside with the "Tonight at the House" stats panel pulling from `/about.json`, and (2) apply `categories_boxes` page style with CSS overrides matching the Liberty Tavern cream/brass aesthetic. Trending Tonight strip is also restructured — moved out of the dark banner and rendered below it as a standalone cream-background section.

</domain>

<decisions>
## Implementation Decisions

### Banner Aside — Stats Panel
- **D-01:** Replace the entire `tavern-banner__aside` content (both "Project of the Night" featured-topic card and "Recent Badges Awarded" badges) with a stats-only "Tonight at the House" panel. No badges in the banner at all — they move to Phase 4 right column.
- **D-02:** Four stats to show: Patrons Inside (`active_users_last_day`), Members (`users_count`), Posts Today (`posts_last_day`), Open Rooms (active categories count) — all from `/about.json`.
- **D-03:** Stats numbers styled italic Playfair Display in `var(--tavern-brass)`. Labels in small caps Inter. Matching Image 4 layout: label left-aligned, number right-aligned, full-width row with rule between items.
- **D-04:** Brass corner-bracket decoration on the stats panel (`::before`/`::after` CSS, matching Image 4 corner marks).

### Data Loading
- **D-05:** Refactor `loadData()` to use `Promise.all()` — fetch `/about.json` and `/top.json` in parallel (not sequentially). Add `/about.json` fetch; remove `/badges.json` fetch (badges no longer in banner).
- **D-06:** Map `/about.json` fields: `about.stats.users_count` → Members, `about.stats.posts_last_day` → Posts Today, `about.stats.active_users_last_day` → Patrons Inside, `about.categories.length` → Open Rooms.

### Trending Tonight — Structure
- **D-07:** Move Trending Tonight out of the dark banner (`tavern-banner__main`) and render it as a separate section below the banner on the cream background. It is NOT inside `.tavern-banner`.
- **D-08:** Trending section rendered by the same `TavernBanner` Glimmer component (it already controls `shouldShow`) but emitted outside the `<section class="tavern-banner">` wrapper — OR split into a sibling outlet render. Claude decides cleanest approach given the single-component pattern already in use.
- **D-09:** "ALL HOT THREADS →" link target: `/hot`. Route kept alive via `top_menu` admin setting.

### Trending Tonight — Layout (match Image 4 exactly)
- **D-10:** Trending strip header: flame emoji/icon + "TRENDING TONIGHT" (small caps) left-aligned, "ALL HOT THREADS →" right-aligned.
- **D-11:** Three topic cards in a horizontal row. Each card shows: category name in small caps (e.g., "THE TOWN SQUARE"), topic title linked, author · reply count · time ago. No views count (Image 4 shows time ago, not views).
- **D-12:** Enrich `toItem()` to capture: `category_id` → resolve to category name, `last_poster_username` → author, `bumped_at` → time ago (formatted as "14M", "2H", etc.).

### Rooms — Category Cards
- **D-13:** Use Discourse's `categories_boxes` desktop category page style. Set `desktop_category_page_style: categories_boxes` via `theme_site_settings` in `about.json` (or document as required admin setting if not overridable by theme).
- **D-14:** CSS overrides on `.category-boxes .category-box` to match Liberty Tavern aesthetic: cream card background, category color as left border or icon accent, Playfair category name, description text, topics/posts counts visible. Existing partial styles in `common.scss` §6 (lines 323–355) are the base — extend them.
- **D-15:** Vertical list card layout (full-width rows with icon + name + description + counts) deferred to future feature request. Phase 3 ships with grid boxes + CSS.

### Claude's Discretion
- Trending section placement: whether to render trending as a second `{{#if this.shouldShow}}` block inside the same template outside the banner `<section>`, or use a second outlet call in `theme-setup.js`. Pick whichever keeps the component boundary cleanest.
- Time-ago formatting: implement a simple inline helper (`bumped_at` → minutes/hours/days since, abbreviated). No external library.
- Category name lookup for trending: use `this.site.categories` (Discourse injects site data) or store category map from a `/categories.json` call if `this.site` is not available in GJS context. Claude picks based on what's actually available.
- Stats panel loading state: show placeholder dashes (`—`) while `/about.json` loads, same as existing `{{#unless this.loading}}` pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design Target
- `CLAUDE.md` — Critical rules (no common/header.html, no appEvents.trigger, etc.)
- Image 4 (provided in discussion session) — full homepage design showing banner, trending, rooms, badges, house rules layout. Key: stats in aside, trending below banner, rooms as vertical list in design but categories_boxes for Phase 3.

### Research & Requirements
- `.planning/research/SUMMARY.md` — outlet names, stack recommendations, top-5 pitfalls
- `.planning/REQUIREMENTS.md` — STATS-01..05 and ROOM-01..04 requirements
- `.planning/ROADMAP.md` — Phase 3 goal and 4 success criteria

### Prior Phase Decisions
- `.planning/phases/01-foundation-repair/01-CONTEXT.md` — D-03: `theme-setup.js` is the api-initializer home; D-01: anonymous CTA → `router.transitionTo("login")`
- `.planning/phases/02-custom-header/02-CONTEXT.md` — D-02: nav label overrides via `locales/en.yml`; established BEM `.tavern-logo__*` pattern

### Existing Code (files being modified)
- `javascripts/discourse/components/tavern-banner.gjs` — main component; `loadData()` refactor, template restructure (aside → stats, trending → external)
- `common/common.scss` §6 (lines 323–355) — existing category styles; extend for rooms cards
- `common/common.scss` §8 (lines 375+) — existing banner styles; trending strip moves out, stats aside styles added
- `about.json` — add `desktop_category_page_style: categories_boxes` to `theme_site_settings` if supported
- `javascripts/discourse/api-initializers/theme-setup.js` — may need second `api.renderInOutlet` for trending section if split from banner component

### Discourse API
- `/about.json` → `about.stats.users_count`, `about.stats.posts_last_day`, `about.stats.active_users_last_day`, `about.categories` (array, count = open rooms)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TavernBanner` Glimmer component (`tavern-banner.gjs`): `@tracked trending`, `@tracked loading`, `loadData()`, `shouldShow` getter, `ajax()` import, `@service router/currentUser/composer` — all reuse directly
- `theme-setup.js`: `api.renderInOutlet("discovery-list-container-top", TavernBanner)` — existing mount point
- `common.scss` §6: `.category-list .category` + `.category-boxes .category-box` — cream bg, oxblood border, Playfair heading, Spectral description already applied. Phase 3 extends.

### Established Patterns
- `@tracked` for reactive data — already in use for `trending`, `badges`, `loading`
- `ajax()` from `discourse/lib/ajax` — established fetch pattern; use for `/about.json`
- BEM: `.tavern-banner__*` — extend for stats panel (`.tavern-banner__stats`, `.tavern-banner__stat-row`)
- `htmlSafe()` for topic titles — already in `toItem()`
- `{{#unless this.loading}}` guard — existing loading pattern; apply to stats too

### Integration Points
- `about.json` `theme_site_settings` block: already has `show_homepage_banner`, `enable_welcome_banner` — add `desktop_category_page_style` here
- `toItem()` function in `loadData()`: extend with `category_id`, `last_poster_username`, `bumped_at` fields from topic object
- `this.site.categories` (Ember `site` service): may provide category name lookup without extra API call

</code_context>

<specifics>
## Specific Ideas

- Stats panel corner brackets: CSS `::before`/`::after` pseudo-elements on `.tavern-banner__stats` with `content: ''`, `border-top/left` and `border-bottom/right` in `var(--tavern-brass)`. Matches Image 4's corner mark aesthetic.
- Trending section heading: `<span>🔥</span> TRENDING TONIGHT` left, `<a href="/hot">ALL HOT THREADS →</a>` right. Use `display: flex; justify-content: space-between` on the heading row.
- Time-ago abbreviation: minutes → "Xm", hours → "Xh", days → "Xd". Compute from `bumped_at` ISO string vs. `Date.now()`.
- Stats numbers font sizing: Image 4 shows numbers significantly larger than labels. Rough sizing: stat number ~28–32px italic Playfair, label ~11px Inter small-caps.
- "Project of the Night" label and featured-topic card: delete completely from template and JS (not just hidden). No dead code.

</specifics>

<deferred>
## Deferred Ideas

- **Vertical list room cards** — Image 4 actually shows colored-circle + name + description + latest post + topics/posts in full-width rows. User elected to defer this in favor of `categories_boxes` grid for Phase 3. Add to roadmap backlog for Phase 5 or post-v1.
- **Badges in banner** — "Recent Badges Awarded" card removed from banner. Badges move to Phase 4 right column.

</deferred>

---

*Phase: 03-homepage-content*
*Context gathered: 2026-04-28*
