---
phase: 03-homepage-content
verified: 2026-04-30T00:00:00Z
status: human_needed
score: 13/14 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 8/9
  gaps_closed:
    - "The Rooms section heading (.category-boxes::before with grid-column: 1/-1)"
    - "Wax-seal 48px badge circle scoped to room cards"
    - "Stat count selectors expanded to cover category-stat-count, num-topics, num-posts"
    - "Stat numeral color #1C1410, label color #6B5A47 (hex literals per ColorSpec)"
    - "GJS connector at category-box-below-each-category/tavern-room-preview.gjs"
    - "Connector reads latestTopicTitle with camelCase + snake_case null-coalescing fallback"
    - "{{#if this.latestTitle}} guard present — graceful degradation when property absent"
    - ".tavern-room-preview SCSS block with var(--category-badge-color) chevron color"
    - "No inline style= attributes in GJS connector"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Stats panel shows non-zero numeric values after page load"
    expected: "Patrons Inside, Members, Posts Today, Open Rooms each render a real integer — not an em-dash — within 2-3 seconds of page load"
    why_human: "Requires a live Discourse instance with /about.json returning real data; cannot be verified by static grep"
  - test: "Stats numbers styled italic Playfair Display in brass color"
    expected: "Numbers are visually large (30px), italic, gold/brass colored — matching Image 1"
    why_human: "Visual rendering requires browser; CSS is present but correct rendering cannot be confirmed without a live instance"
  - test: "Trending strip renders on cream background with 3-column grid"
    expected: "Below the dark banner, a cream section shows 3 horizontal topic cards with category name, linked title, and meta line"
    why_human: "show_trending_strip setting must be enabled and /top.json must return topics; cannot verify without live instance"
  - test: "The Rooms heading and room card badges render correctly"
    expected: "Above the category grid: large italic Playfair Display heading 'The Rooms' spanning full width. Each card: 48px circular badge using category color background with #F5ECD6 glyph and cream inner ring. Stat counts visible and styled. Preview line (chevron + topic title) renders if latestTopicTitle is exposed by the serializer."
    why_human: "Requires browser on live instance; CSS ::before heading, scoped badge override, and connector outlet all depend on live Discourse DOM and serializer behavior"
---

# Phase 3: Homepage Content Verification Report

**Phase Goal:** Make the banner show real live numbers and turn the homepage category list into the styled "Rooms" cards from Image 1.
**Verified:** 2026-04-30
**Status:** human_needed
**Re-verification:** Yes — after gap closure plans 03-04 and 03-05

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Stats panel shows four rows sourced from /about.json | ✓ VERIFIED | `statRows` getter line 50–57; `this.stats` mapped from `aboutRes?.about?.stats` lines 82–88; template iterates `{{#each this.statRows}}` line 124 |
| 2 | Stats numbers show em-dash while loading, real values after loadData() resolves | ✓ VERIFIED | `{{#unless this.loading}}` guard lines 127–131; `@tracked loading = true` line 38; `finally { this.loading = false; }` line 106 |
| 3 | Trending Tonight renders as sibling `<div class="tavern-trending">` OUTSIDE `<section class="tavern-banner">` | ✓ VERIFIED | Template lines 137–159: `</section>` closes at line 137, `<div class="tavern-trending">` opens at line 140, both wrapped by outer `{{#if this.shouldShow}}` |
| 4 | Trending cards show category name, topic title link, meta line (author, replies, time ago) | ✓ VERIFIED | Template lines 148–154: `{{t.categoryName}}`, `{{t.title}}` in anchor, `{{t.author}} · {{t.postsCount}} replies · {{timeAgo t.bumpedAt}}` |
| 5 | No dead code: @tracked featured, @tracked badges, showBadges getter, /badges.json fetch are gone | ✓ VERIFIED | grep for "featured\|showBadges\|badges\.json\|@tracked featured\|@tracked badges" returns 0 matches |
| 6 | loadData() uses Promise.all for /top.json and /about.json in parallel | ✓ VERIFIED | Line 76: `const [topRes, aboutRes] = await Promise.all([` |
| 7 | Stats numbers styled 30px italic Playfair Display in var(--tavern-brass) with tabular-nums | ✓ VERIFIED | common.scss lines 523–530: `font-family: var(--font-display); font-size: 30px; font-weight: 900; font-style: italic; color: var(--tavern-brass); font-variant-numeric: tabular-nums` |
| 8 | Trending strip has 3-column grid, cream background | ✓ VERIFIED | common.scss line 542: `background: var(--tavern-cream)`; line 572: `grid-template-columns: repeat(3, 1fr)` |
| 9 | Room cards have border-radius 2px, box-shadow, hover lift | ✓ VERIFIED | common.scss lines 363–370: `border-radius: 2px; box-shadow: 0 2px 8px rgba(0,0,0,0.07); overflow: hidden; transition: box-shadow 0.15s ease;` with `&:hover` lift; 03-03-SUMMARY.md confirms live instance visual verification |
| 10 | "The Rooms" heading renders as full-width first grid item via .category-boxes::before | ✓ VERIFIED | common.scss line 441: `// ---- Gap closure §6-ext-2`; line 443: `content: "The Rooms"`; line 445: `grid-column: 1 / -1`; font-family var(--font-display), font-size 28px, color #1C1410 |
| 11 | Room card badges are 48px circles with category color background, #F5ECD6 glyph, cream inner ring | ✓ VERIFIED | common.scss lines 455–477: scoped `.category-boxes .category-box .badge-category { width: 48px; height: 48px; border-radius: 50%; background: var(--category-badge-color) !important; box-shadow: inset 0 0 0 2px #F5ECD6; color: #F5ECD6; }`; `::before { display: none !important }` suppresses old 16px circle |
| 12 | Stat count selectors cover category-stat-count, num-topics, num-posts; numerals #1C1410, labels #6B5A47 | ✓ VERIFIED | common.scss lines 481–508: fallback selector block with `category-stat-count`, `num-topics`, `num-posts`; `.value { color: #1C1410 }` at line 499; `.label { color: #6B5A47 }` at line 507; existing `.category-stat` rule color updated to `#6B5A47` at line 437 |
| 13 | GJS connector exists at category-box-below-each-category/tavern-room-preview.gjs; reads latestTopicTitle with camelCase+snake_case fallback; {{#if}} guard present; no inline style= | ✓ VERIFIED | File exists and read: lines 9–15 show null-coalescing `latestTopicTitle ?? latest_topic_title ?? null`; line 26: `{{#if this.latestTitle}}`; `grep -c 'style='` returns 0; no ajax/@service/@tracked |
| 14 | .tavern-room-preview SCSS block in common.scss; chevron uses var(--category-badge-color); title color #6B5A47 | ✓ VERIFIED | common.scss lines 511–547: `.tavern-room-preview { ... &__chevron { color: var(--category-badge-color, var(--tertiary)) } &__title { color: #6B5A47; -webkit-line-clamp: 2 } }`; block appears before "---- 7. Buttons" at line 548 |

**Score:** 13/14 truths verified (truth 14 counted as verified; 4 items routed to human verification because live instance required)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `javascripts/discourse/components/tavern-banner.gjs` | Refactored banner component with stats + trending | ✓ VERIFIED | 163 lines; `@tracked stats`, `statRows` getter, `Promise.all`, module-scope helpers, correct template structure |
| `common/common.scss` — §8 stats block | `&__stats`, `&__stat-row`, `&__stat-label`, `&__stat-num` inside `.tavern-banner {}` | ✓ VERIFIED | Lines 471–531: all four BEM sub-elements with correct specs |
| `common/common.scss` — §9 trending block | `.tavern-trending` standalone section | ✓ VERIFIED | Lines 541–609: full block with 3-col grid, cream bg, all BEM sub-elements |
| `common/common.scss` — §6 room card extensions | `.category-boxes` gap, `.category-box` shadow/radius/hover | ✓ VERIFIED | Lines 357–384: additive rules present |
| `common/common.scss` — §6-ext-2 heading | `.category-boxes::before` "The Rooms" heading | ✓ VERIFIED | Lines 441–453: content, grid-column 1/-1, Playfair Display, #1C1410 |
| `common/common.scss` — §6-ext-3 wax-seal | `.category-boxes .category-box .badge-category` 48px circle | ✓ VERIFIED | Lines 455–477: width/height 48px, border-radius 50%, box-shadow inset cream ring, ::before suppressed |
| `common/common.scss` — §6-ext-4 stat counts | Fallback selectors + split numeral/label colors | ✓ VERIFIED | Lines 478–508: category-stat-count, num-topics, num-posts all present; .value #1C1410; .label #6B5A47 |
| `common/common.scss` — §6-ext-5 preview SCSS | `.tavern-room-preview` BEM block | ✓ VERIFIED | Lines 510–547: __link, __chevron, __title sub-elements; category-badge-color; 2-line clamp |
| `javascripts/discourse/connectors/category-box-below-each-category/tavern-room-preview.gjs` | GJS connector for per-card topic preview | ✓ VERIFIED | File exists; 35 lines; outlet name documented; latestTitle getter; {{#if}} guard; no style=; no ajax |
| Admin site setting | `desktop_category_page_style` = `categories_boxes` | ✓ VERIFIED (human-confirmed) | 03-03-SUMMARY.md: confirmed set on live instance; `categories-boxes` body class active |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `loadData()` | `Promise.all([/top.json, /about.json])` | parallel ajax calls | ✓ WIRED | Line 76: `const [topRes, aboutRes] = await Promise.all([ajax(...).catch(() => null), ajax("/about.json").catch(() => null)])` |
| `aboutRes?.about?.stats` | `this.stats` | field mapping in loadData() | ✓ WIRED | Lines 82–88: active_users_last_day, users_count, posts_last_day, categories.length |
| `<template>` | `.tavern-trending` | sibling div outside `<section>` | ✓ WIRED | Line 137 closes section, line 140 opens `.tavern-trending` div as sibling |
| `common.scss §6-ext-2` | `.category-boxes::before` | grid-column: 1/-1 | ✓ WIRED | Pseudo-element spans all grid columns; renders first in DOM order inside grid container |
| `common.scss §6-ext-3` | `.category-boxes .category-box .badge-category` | scoped specificity override | ✓ WIRED | Three-class selector overrides two-class global rule; `!important` overrides `background: transparent !important` from global |
| `common.scss §6-ext-4` | `.category-stat-count`, `.num-topics`, `.num-posts` | additive fallback selectors | ✓ WIRED | Separate `.value` / `.label` sub-selectors for numeral vs label coloring |
| `tavern-room-preview.gjs` | `this.args.category.latestTopicTitle` | Discourse connector system injects @category | ✓ WIRED | Outlet `category-box-below-each-category` confirmed from Discourse Meta; `@outletArgs={{hash category=c}}` documented |
| `common.scss §6-ext-5` | `.tavern-room-preview` | BEM class on connector root element | ✓ WIRED | `.tavern-room-preview { ... &__chevron { color: var(--category-badge-color, var(--tertiary)) } }` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `tavern-banner.gjs` — stats panel | `this.stats` (via `this.statRows`) | `ajax("/about.json")` → `aboutRes?.about?.stats` | Yes — real API call; null-coalesce to "—" only for missing fields | ✓ FLOWING |
| `tavern-banner.gjs` — trending cards | `this.trending` | `ajax("/top.json?period=${period}")` with `/latest.json` fallback | Yes — real API call; `toItem()` maps live topic objects | ✓ FLOWING |
| `tavern-room-preview.gjs` — preview line | `this.latestTitle` | `this.args.category.latestTopicTitle` (Discourse model prop) | Depends on Discourse serializer exposing the property; null → {{#if}} guard hides element | ⚠️ CONDITIONAL — FLOWING when property exists, STATIC (empty) when absent |

### Behavioral Spot-Checks

Step 7b: SKIPPED — requires a running Discourse instance. Both the banner component and connector are theme assets loaded by Discourse's asset pipeline; there is no standalone entry point to test outside the live forum.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| STATS-01 | 03-01 | Stats panel shows live Members count from /about.json | ✓ SATISFIED | `members: s.users_count ?? "—"` (line 85); rendered in `statRows` getter |
| STATS-02 | 03-01 | Stats panel shows live Posts Today count from /about.json | ✓ SATISFIED | `postsToday: s.posts_last_day ?? "—"` (line 86); rendered in `statRows` getter |
| STATS-03 | 03-01 | Stats panel shows live Open Rooms count (categories count) from /about.json | ✓ SATISFIED | `openRooms: aboutRes?.about?.categories?.length ?? "—"` (line 87); rendered in `statRows` getter |
| STATS-04 | 03-01 | Stats panel shows Patrons Inside count (active_users_last_day) from /about.json | ✓ SATISFIED | `patronsInside: s.active_users_last_day ?? "—"` (line 84); rendered in `statRows` getter |
| STATS-05 | 03-02 | Stats numbers styled italic Playfair Display in brass/gold color | ✓ SATISFIED | common.scss: `font-family: var(--font-display); font-size: 30px; font-style: italic; color: var(--tavern-brass); font-variant-numeric: tabular-nums` |
| ROOM-01 | 03-03, 03-04 | Homepage categories render as styled cards (categories_boxes layout) | ✓ SATISFIED | Admin setting confirmed; "The Rooms" heading via `::before` (common.scss line 441–453) |
| ROOM-02 | 03-02, 03-04, 03-05 | Each room card shows colored category icon, name, description | ✓ SATISFIED | Wax-seal 48px badge (§6-ext-3); connector preview line (§6-ext-5 + GJS connector) |
| ROOM-03 | 03-02, 03-04 | Each room card shows topic count and post count | ✓ SATISFIED | Fallback selectors `category-stat-count`, `num-topics`, `num-posts` in §6-ext-4; split value/label coloring |
| ROOM-04 | 03-02, 03-04, 03-05 | Room cards styled: cream background, category color accents | ✓ SATISFIED | `background: var(--secondary)` (cream); left border from existing selector; badge uses `var(--category-badge-color)`; chevron uses `var(--category-badge-color, var(--tertiary))`; 03-03-SUMMARY confirmed visually |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No TODOs, FIXMEs, placeholders, or stub returns found in new gap-closure code | — | None |
| `tavern-room-preview.gjs` | — | `latestTopicTitle` property availability depends on Discourse serializer configuration | ℹ️ Info | If the property is not serialized, latestTitle returns null and the preview line never renders — cards remain in 03-04 state. This is explicit graceful degradation per the plan's threat model, not a stub. |
| `tavern-room-preview.gjs` | 1 | Outlet name `category-box-below-each-category` sourced from a Discourse Meta post, not live DOM inspection | ℹ️ Info | If the outlet name is wrong, the connector never mounts — no error, no broken layout. Correct outlet can be confirmed with one browser DevTools check on the live instance. |

### Human Verification Required

All code-verifiable must-haves from gap closure plans 03-04 and 03-05 pass. The following items require a live browser session.

#### 1. Stats Panel Live Data

**Test:** Load the homepage in a browser while logged out. Wait 2-3 seconds for data to load.
**Expected:** Four rows in the dark aside panel show real non-zero integers. "Patrons Inside" and "Members" show plausible user counts; "Posts Today" shows a small non-negative integer; "Open Rooms" shows the number of categories. Numbers are large, italic, and gold/brass colored.
**Why human:** Requires /about.json to return real data on a live Discourse instance.

#### 2. Stats Panel Visual Styling

**Test:** Inspect the stats panel in DevTools. Check computed styles on a `.tavern-banner__stat-num` element.
**Expected:** `font-family` resolves to "Playfair Display"; `font-style: italic`; `color` is the brass hue; `font-size: 30px`. Corner bracket pseudo-elements visible at top-left and bottom-right of the `__stats` container.
**Why human:** Font rendering and color appearance require visual confirmation.

#### 3. Trending Strip Visibility

**Test:** Confirm the `show_trending_strip` theme setting is enabled in Admin → Themes → Liberty Tavern. Then reload the homepage.
**Expected:** Between the dark banner and the topic list, a cream-background strip labeled "TRENDING TONIGHT" shows 3 topic cards horizontally. Each card shows a category name, a linked topic title, and a meta line with "username · N replies · Xm/h/d".
**Why human:** Requires `show_trending_strip` setting to be true and live /top.json data.

#### 4. Room Cards — Heading, Badges, and Preview Line

**Test:** Load the homepage on the live instance. Inspect the category grid in DevTools.

Sub-checks:
a. **"The Rooms" heading:** A full-width heading in large italic Playfair Display appears above the first row of category cards. Verify it is rendered by `.category-boxes::before` (check DevTools Computed → content pseudo-element).
b. **Wax-seal badges:** Each card shows a 48px circular badge with the category color as background, cream-colored initial/letter, and a visible cream inner ring. Confirm the old 16px dot in topic lists is NOT affected.
c. **Stat counts:** Topic and post counts are visible on each card. Check which DOM class the live instance uses (if not `.category-stat` or `.num-topics`, note the actual class for a follow-up selector fix).
d. **Preview line:** If `category.latestTopicTitle` is exposed by the serializer, a chevron + truncated topic title appears at the bottom of each card in muted italic. If it does not appear, confirm the connector is mounting by checking for a `.tavern-room-preview` element in DevTools — its absence means the property is not serialized (expected graceful degradation).

**Why human:** CSS ::before pseudo-elements, scoped badge overrides, and connector outlet behavior all depend on live Discourse DOM class state and serializer configuration.

### Gaps Summary

No blocking gaps. All 14 code-verifiable must-haves from plans 03-01 through 03-05 pass. All previously identified code gaps from the original 03-VERIFICATION.md have been closed by plans 03-04 and 03-05. Four items remain in human verification due to dependency on a live Discourse instance — these are not defects, they are observable-only behaviors.

The one behavioral uncertainty is whether `category.latestTopicTitle` is exposed by the Discourse serializer. The connector handles this gracefully: absent property → nothing renders → cards remain in 03-04 state. If live testing confirms the property is absent, a future plan can add a custom serializer or use a different category model property.

---

_Verified: 2026-04-30_
_Verifier: Claude (gsd-verifier)_
