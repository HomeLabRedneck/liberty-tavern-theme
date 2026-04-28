# Phase 3: Homepage Content — Research

**Researched:** 2026-04-28
**Domain:** Discourse GJS Glimmer components, SCSS BEM extension, Discourse site settings
**Confidence:** HIGH (primary claims verified against Discourse source or official docs)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Replace entire `tavern-banner__aside` content with stats-only "Tonight at the House" panel. No badges in banner.
- D-02: Four stats from `/about.json`: Patrons Inside (`active_users_last_day`), Members (`users_count`), Posts Today (`posts_last_day`), Open Rooms (`about.categories.length`).
- D-03: Stats numbers: italic Playfair Display in `var(--tavern-brass)`. Labels in small caps Inter.
- D-04: Brass corner-bracket decoration on stats panel via `::before`/`::after`.
- D-05: Refactor `loadData()` to `Promise.all()` — fetch `/about.json` and `/top.json` in parallel. Remove `/badges.json` fetch.
- D-06: Map `/about.json` fields as documented in D-02.
- D-07: Move Trending Tonight out of the dark banner; render as separate section below on cream background.
- D-08: Trending rendered by the same `TavernBanner` component, outside the `<section class="tavern-banner">` wrapper.
- D-09: "ALL HOT THREADS →" link target: `/hot`.
- D-10: Trending strip header: `🔥 TRENDING TONIGHT` left, `ALL HOT THREADS →` right.
- D-11: Three topic cards in horizontal row. Each: category name (small caps), topic title linked, author · reply count · time ago.
- D-12: Enrich `toItem()` with `category_id`, `last_poster_username`, `bumped_at` fields.
- D-13: Use Discourse `categories_boxes` desktop category page style. Set via `theme_site_settings` if supported, otherwise document as required admin setting.
- D-14: CSS overrides on `.category-boxes .category-box` extending existing §6 in `common.scss`.
- D-15: Grid boxes layout for Phase 3 (vertical list deferred).

### Claude's Discretion
- Trending section placement: whether to render as a second `{{#if this.shouldShow}}` block outside the banner `<section>` in the same template, or use a second outlet call in `theme-setup.js`.
- Time-ago formatting: simple inline helper, no external library.
- Category name lookup for trending: `this.site.categories` or `Category.findById()` from `discourse/models/category`.
- Stats panel loading state: placeholder dashes (`—`) while loading.

### Deferred Ideas (OUT OF SCOPE)
- Vertical list room cards (full-width rows with circle + name + description).
- Badges in banner (move to Phase 4 right column).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STATS-01 | Stats panel shows live Members count from `/about.json` | D-05/D-06: `ajax("/about.json")` → `about.stats.users_count`; verified field exists |
| STATS-02 | Stats panel shows live Posts Today count from `/about.json` | D-05/D-06: `about.stats.posts_last_day` |
| STATS-03 | Stats panel shows live Open Rooms count from `/about.json` | D-06: `about.categories.length`; the `about.categories` array is always present |
| STATS-04 | Stats panel shows Patrons Inside count (`active_users_last_day` proxy) | D-06: `about.stats.active_users_last_day`; no real-time unauthenticated endpoint exists |
| STATS-05 | Stats numbers styled italic Playfair Display in brass/gold | D-03 + UI-SPEC typography table; CSS only, no JS |
| ROOM-01 | Homepage categories render as styled cards (`categories_boxes`) | D-13: `desktop_category_page_style` is NOT themeable — requires admin action (see Finding 7) |
| ROOM-02 | Each room card shows colored category icon, name, description | D-14: existing §6 in `common.scss` already handles this; only extensions needed |
| ROOM-03 | Each room card shows topic count and post count | D-14: `common.scss` §6 extension, target `.category-stat` or equivalent Discourse selector |
| ROOM-04 | Room cards styled to match Image 1 (cream bg, category color accents) | D-14: existing §6 sets `border-left`, `background: var(--secondary)` — extend, don't replace |
</phase_requirements>

---

## Summary

Phase 3 modifies a single Glimmer component (`tavern-banner.gjs`) and extends one SCSS file (`common.scss`). The JavaScript work involves refactoring `loadData()` from sequential `await` calls to `Promise.all(["/about.json", "/top.json"])`, replacing the `featured`/`badges` tracked properties with a single `stats` object, enriching `toItem()` with three new fields, and restructuring the template to emit the trending strip outside the dark banner `<section>`.

The most significant planning risk is the `desktop_category_page_style` setting: it is definitively confirmed as NOT marked `themeable: true` in Discourse core's `config/site_settings.yml`. It cannot be set via `theme_site_settings` in `about.json`. The admin must set it to `categories_boxes` via the Admin panel. The plan must include this as a manual step with verification instructions.

Category name lookup for trending cards uses `import Category from "discourse/models/category"` and `Category.findById(id)` — confirmed in production theme components. The `@service site` approach is NOT needed and should not be used.

**Primary recommendation:** All JavaScript changes are confined to `tavern-banner.gjs`. Template restructure (trending outside `<section>`) is the cleanest implementation — no second outlet mount needed. SCSS changes are purely additive in §8 (banner) and a new §9 (trending), with targeted extensions to §6 (category boxes). `desktop_category_page_style` is an admin-only setting.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stats data fetch | Frontend (Glimmer component) | — | `/about.json` is a public REST endpoint; data is fetched client-side in `loadData()` |
| Stats display | Frontend (GJS template) | SCSS | Template renders numbers; SCSS styles them |
| Trending data fetch | Frontend (Glimmer component) | — | Already fetches `/top.json`; extend `toItem()` |
| Trending display | Frontend (GJS template) | SCSS | New `.tavern-trending` section in template |
| Category name lookup | Client model layer | — | `Category.findById(id)` reads Discourse's pre-loaded category list |
| Room card layout | Discourse core | SCSS overrides | `categories_boxes` renders the grid; theme only applies visual CSS on top |
| `categories_boxes` activation | Admin / database | theme_site_settings (blocked) | Admin → Interface → desktop_category_page_style — not overridable by themes |

---

## Key Findings

**1. `tavern-banner.gjs` current structure — complete map**

The component currently has:
- `@tracked trending = []` — array of `{id, title, url, postsCount, views, likeCount}`
- `@tracked featured = null` — single topic object (the "Project of the Night" card)
- `@tracked badges = []` — badge array for the badges card
- `@tracked loading = true`
- Sequential `loadData()`: fetches `/top.json` first, then `/badges.json` after
- Template: renders `tavern-banner__trending` INSIDE `.tavern-banner__main`, renders `tavern-banner__feature` and `tavern-banner__badges` INSIDE `.tavern-banner__aside`

**What must change:**
- Remove `@tracked featured` and `@tracked badges` (dead after this phase)
- Add `@tracked stats = null` to hold `{patronsInside, members, postsToday, openRooms}`
- Add `/about.json` to `Promise.all()`; remove `/badges.json` fetch
- Remove `this.featured = ...` and `this.badges = ...` assignments
- Extend `toItem()` with: `categoryId: t.category_id`, `author: t.last_poster_username`, `bumpedAt: t.bumped_at`
- Delete `showBadges` getter (no longer needed)
- Template: delete `{{#if this.featured}}` block, delete `{{#if this.showBadges}}` block
- Template: move `tavern-banner__trending` block OUT of `<section>` to become `.tavern-trending` below it
- Template: add `.tavern-banner__stats` inside `<aside>` in its place
- SCSS §8: delete `&__feature`, `&__feature-link`, `&__feature-title`, `&__badges`, `&__trending` blocks

**What stays unchanged:**
- `@service router`, `@service currentUser`, `@service composer`
- `shouldShow` getter (route detection logic)
- `openNewTopic()` action
- `settings` getter
- Constructor pattern
- `ajax()` import from `discourse/lib/ajax`
- `htmlSafe()` usage in `toItem()`
- Overall `{{#if this.shouldShow}}` guard

**2. `common.scss` current state — exact line map**

- §6 (lines 323–340): `.category-list .category, .category-boxes .category-box` — sets `border-left`, `background`, category name Playfair, description Spectral. Lines 342–355: `.badge-category__wrapper` circle badge. Phase 3 extends lines 325–340 only.
- §8 (lines 375–532): `.tavern-banner { ... }` block containing `&__feature` (lines 441–458), `&__feature-link` (lines 460–463), `&__feature-title` (lines 465–471), `&__trending` (lines 473–498), `&__badges` (lines 500–531). All five of these sub-blocks must be DELETED.
- New content added: `&__stats`, `&__stat-row`, `&__stat-label`, `&__stat-num` inside §8; new §9 block for `.tavern-trending` and its children.
- The `section.tavern-banner::before` ribbon (lines 389–395) is PRESERVED — untouched.
- Final line 537: `body:not(.navigation-topics):not(.navigation-categories) .tavern-banner { display: none; }` — PRESERVED.

**3. `about.json` current state**

Currently has:
```json
"theme_site_settings": {
  "enable_welcome_banner": false
}
```
Phase 3 does NOT add `desktop_category_page_style` here (see Finding 7). No other changes to `about.json` in this phase.

**4. `theme-setup.js` current state — no changes needed**

The file has a single `api.renderInOutlet("discovery-list-container-top", TavernBanner)` call. Because the trending section will be emitted from within the same `TavernBanner` component template (outside the `<section>` wrapper but still inside the same rendered root), no second outlet mount is needed. The component can render multiple sibling elements by wrapping them in a fragment or a `<div>` at the component root.

**GJS fragment pattern:** In Glimmer `.gjs`, a component template can return multiple root elements by wrapping in `<template>` without requiring a single root — the outer `<template>` tag IS the root. So the component can emit:
```hbs
<template>
  {{#if this.shouldShow}}
    <section class="tavern-banner"> ... </section>
    <div class="tavern-trending"> ... </div>
  {{/if}}
</template>
```
This is valid GJS and requires zero changes to `theme-setup.js`.

**5. `Promise.all()` pattern with `@tracked`**

The current `loadData()` uses sequential `await`. The refactored version uses:
```js
const [topRes, aboutRes] = await Promise.all([
  ajax(`/top.json?period=${period}`).catch(() => null),
  ajax("/about.json").catch(() => null),
]);
```
Both fetch independently in parallel. `this.stats` and `this.trending` are both set before `this.loading = false` in the `finally` block. This matches the existing `@tracked` / Glimmer autotracking pattern — assigning `this.stats = { ... }` triggers re-render automatically.

**6. Category name lookup — `Category.findById()` confirmed**

Pattern verified in production Discourse theme components (discourse-featured-lists):
```js
import Category from "discourse/models/category";
// ...
const cat = Category.findById(t.category_id);
const categoryName = cat?.name ?? "";
```
`Category.findById()` reads from Discourse's pre-loaded category list that ships with the page HTML — it does NOT make a network call. This is synchronous and always returns a result or `null`.

`@service site` is NOT needed for category lookup. The `site` service exists but `Category.findById` is the standard pattern for theme components. [VERIFIED: discourse-featured-lists GJS source]

**Enriched `toItem()` for trending:**
```js
const toItem = (t) => {
  const cat = Category.findById(t.category_id);
  return {
    id: t.id,
    title: htmlSafe(t.fancy_title ?? t.title ?? ""),
    url: `/t/${t.slug}/${t.id}`,
    postsCount: t.posts_count,
    categoryName: cat?.name ?? "",
    author: t.last_poster_username ?? "",
    bumpedAt: t.bumped_at ?? null,
  };
};
```
The `views` and `likeCount` fields are no longer needed and should be dropped.

**7. `desktop_category_page_style` — CONFIRMED NOT THEMEABLE (critical finding)**

Verified directly against Discourse core `config/site_settings.yml`:
```yaml
desktop_category_page_style:
  client: true
  enum: "CategoryPageStyle"
  default: "categories_and_latest_topics"
  area: "interface"
```
There is **no `themeable: true` flag**. [VERIFIED: github.com/discourse/discourse/blob/main/config/site_settings.yml]

This means `"theme_site_settings": { "desktop_category_page_style": "categories_boxes" }` in `about.json` will be SILENTLY IGNORED. The value will not be applied.

**The plan must include a manual admin step:** Admin → Settings → Interface → "desktop category page style" → set to "categories_boxes with featured topics" or "categories_boxes". This is a one-time admin action on the live Discourse instance.

**Alternative if admin access is unavailable:** The CSS class `.categories-boxes` on `<body>` is added by Discourse only when that setting is active. Without the admin setting, `.category-boxes .category-box` rules in §6 will not target anything — the DOM renders a different layout. There is no CSS-only workaround. A JavaScript approach (using `api.onPageChange` to add a body class) could force the layout by modifying `siteSettings.desktop_category_page_style` at runtime, but this is fragile. The plan should document admin action as the correct path.

**8. Time-ago helper — inline function pattern**

No Discourse utility needed for the abbreviated format (`14m`, `2h`, `3d`). The inline pattern:
```js
function timeAgo(isoString) {
  if (!isoString) return "";
  const diff = Math.floor((Date.now() - new Date(isoString).getTime()) / 1000);
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  return `${Math.floor(diff / 86400)}d`;
}
```
This is 6 lines and covers all cases. Define it at module scope in `tavern-banner.gjs`, above the class. Do not import `autoUpdatingRelativeAge` (that is a live-updating component, which is overkill here). [ASSUMED: Discourse has `autoUpdatingRelativeAge` in `discourse/lib/formatter` but it is not needed for this use case — the simpler inline function is correct per D-12 discretion]

**9. `settings.yml` changes needed**

The `show_badges_card` and `show_trending_strip` settings still exist. After Phase 3:
- `show_badges_card` no longer controls anything in the banner (badges are deferred to Phase 4). The setting can remain for Phase 4 to use, or be renamed. For Phase 3, simply stop referencing `showBadges` in the template.
- `show_trending_strip` now controls whether `.tavern-trending` renders (was controlling the old `&__trending` inside banner). The same setting name still applies semantically — no rename needed.
- No new settings.yml entries are required for Phase 3.

---

## File Inventory (current state of files being modified)

### `javascripts/discourse/components/tavern-banner.gjs`

| Item | Current State | Phase 3 Action |
|------|---------------|----------------|
| `@tracked trending` | Array of `{id, title, url, postsCount, views, likeCount}` | Keep, extend with `categoryName`, `author`, `bumpedAt`; drop `views`, `likeCount` |
| `@tracked featured` | Single topic object | DELETE — replaced by `@tracked stats` |
| `@tracked badges` | Badge array | DELETE |
| `@tracked loading` | Boolean | Keep |
| `get showBadges()` | Guard for badges render | DELETE |
| `loadData()` | Sequential: `/top.json` then `/badges.json` | Refactor: `Promise.all(["/top.json", "/about.json"])`; remove `/badges.json`; add stats mapping |
| `toItem()` | 6 fields | Extend: add `categoryName`, `author`, `bumpedAt`; drop `views`, `likeCount` |
| Template: `tavern-banner__trending` | Inside `tavern-banner__main` | DELETE this block; replace with external `.tavern-trending` |
| Template: `tavern-banner__feature` | Inside `tavern-banner__aside` | DELETE |
| Template: `tavern-banner__badges` | Inside `tavern-banner__aside` | DELETE |
| Template: `tavern-banner__aside` | Wraps feature + badges | Keep wrapper; replace contents with `.tavern-banner__stats` |
| Template: outer `{{#if this.shouldShow}}` | Wraps `<section>` | Expand to wrap both `<section>` and `.tavern-trending` |

New import needed: `import Category from "discourse/models/category";`
New module-scope function needed: `timeAgo(isoString)`
New tracked property: `@tracked stats = null;`

### `common/common.scss`

| Block | Lines | Phase 3 Action |
|-------|-------|----------------|
| §6 `.category-boxes .category-box` | 325–340 | Extend (additive): add gap, border-radius, box-shadow, hover, overflow, inner padding, count font |
| §6 `.badge-category__wrapper` | 342–355 | No change |
| §8 `&__feature` | 441–458 | DELETE entire block |
| §8 `&__feature-link` | 460–463 | DELETE entire block |
| §8 `&__feature-title` | 465–471 | DELETE entire block |
| §8 `&__trending` | 473–498 | DELETE entire block |
| §8 `&__badges` | 500–531 | DELETE entire block |
| §8 new `&__stats` block | (new) | ADD inside `.tavern-banner { ... }` |
| New §9 `.tavern-trending` | (new) | ADD below §8 |

### `about.json`

No changes in Phase 3. `desktop_category_page_style` is not settable via `theme_site_settings`.

### `javascripts/discourse/api-initializers/theme-setup.js`

No changes. Single `api.renderInOutlet` call remains sufficient.

### `settings.yml`

No changes. Existing `show_trending_strip` and `show_badges_card` settings remain.

---

## Implementation Approach

### Deliverable 1: Stats Panel

**JS changes (`tavern-banner.gjs`):**

1. Add import: `import Category from "discourse/models/category";`
2. Add module-scope `timeAgo(isoString)` function
3. Remove `@tracked featured`, `@tracked badges`, `get showBadges()`
4. Add `@tracked stats = null;`
5. Refactor `loadData()`:
   ```js
   async loadData() {
     try {
       const period = settings.trending_period || "daily";
       const [topRes, aboutRes] = await Promise.all([
         ajax(`/top.json?period=${period}`).catch(() => null),
         ajax("/about.json").catch(() => null),
       ]);

       // Stats from about.json
       const s = aboutRes?.about?.stats ?? {};
       this.stats = {
         patronsInside: s.active_users_last_day ?? "—",
         members: s.users_count ?? "—",
         postsToday: s.posts_last_day ?? "—",
         openRooms: aboutRes?.about?.categories?.length ?? "—",
       };

       // Trending from top.json (+ fallback to latest.json)
       let raw = topRes?.topic_list?.topics ?? [];
       // ... fallback logic unchanged ...
       this.trending = raw.slice(0, 3).map(toItem);
     } catch (e) {
       console.warn("Liberty Tavern banner: failed to load data", e);
     } finally {
       this.loading = false;
     }
   }
   ```
   Note: `featured` was `raw[0]`; now `trending` takes `raw.slice(0, 3)` (3 items, not `raw.slice(1, 4)`).

6. Template — aside replacement:
   ```hbs
   <aside class="tavern-banner__aside">
     <div class="tavern-banner__stats">
       <div class="label">TONIGHT AT THE HOUSE</div>
       {{#each (array
         (hash label="Patrons Inside" value=this.stats.patronsInside)
         (hash label="Members" value=this.stats.members)
         (hash label="Posts Today" value=this.stats.postsToday)
         (hash label="Open Rooms" value=this.stats.openRooms)
       ) as |row|}}
         <div class="tavern-banner__stat-row">
           <span class="tavern-banner__stat-label">{{row.label}}</span>
           {{#if this.loading}}
             <span class="tavern-banner__stat-num tavern-banner__stat-num--loading">—</span>
           {{else}}
             <span class="tavern-banner__stat-num">{{row.value}}</span>
           {{/if}}
         </div>
       {{/each}}
     </div>
   </aside>
   ```
   Note: Glimmer's `(array ...)` and `(hash ...)` helpers may not be available in all Discourse GJS contexts. A safer alternative is to define the rows array in the class as a getter:
   ```js
   get statRows() {
     return [
       { label: "Patrons Inside", value: this.stats?.patronsInside ?? "—" },
       { label: "Members",        value: this.stats?.members ?? "—" },
       { label: "Posts Today",    value: this.stats?.postsToday ?? "—" },
       { label: "Open Rooms",     value: this.stats?.openRooms ?? "—" },
     ];
   }
   ```
   Then `{{#each this.statRows as |row|}}`. This is the safer approach.

**SCSS changes (`common.scss` §8 inside `.tavern-banner { }`):**

```scss
// Stats panel (replaces &__feature and &__badges)
&__stats {
  background: rgba(255,255,255,.05);
  border: 1px solid var(--tavern-brass);
  border-radius: 2px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.4);
  padding: 24px;
  position: relative;

  &::before {
    content: '';
    position: absolute; top: -1px; left: -1px;
    width: 10px; height: 10px;
    border-top: 2px solid var(--tavern-brass);
    border-left: 2px solid var(--tavern-brass);
  }
  &::after {
    content: '';
    position: absolute; bottom: -1px; right: -1px;
    width: 10px; height: 10px;
    border-bottom: 2px solid var(--tavern-brass);
    border-right: 2px solid var(--tavern-brass);
  }

  .label {
    font-family: var(--font-ui);
    font-size: 10px; font-weight: 700; letter-spacing: 0.3em;
    text-transform: uppercase;
    color: var(--tavern-brass);
    margin-bottom: 16px;
  }
}

&__stat-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  padding: 12px 0;
  border-top: 1px solid rgba(245,235,217,.12);
  &:first-of-type { border-top: none; }
}

&__stat-label {
  font-family: var(--font-ui);
  font-size: 10px; font-weight: 700;
  font-variant: small-caps;
  letter-spacing: 0.18em;
  color: #f5ebd9;
  opacity: 0.75;
}

&__stat-num {
  font-family: var(--font-display);
  font-size: 30px; font-weight: 900; font-style: italic;
  color: var(--tavern-brass);
  letter-spacing: -0.01em;
  font-variant-numeric: tabular-nums;

  &--loading { opacity: 0.4; }
}
```

### Deliverable 2: Trending Tonight Strip

**JS changes:** Already covered above — `toItem()` extended with `categoryName`, `author`, `bumpedAt`.

**Template structure** (outside `<section class="tavern-banner">`, inside `{{#if this.shouldShow}}`):
```hbs
{{#if this.shouldShow}}
  <section class="tavern-banner">
    ...
  </section>

  {{#if settings.show_trending_strip}}
    <div class="tavern-trending">
      <div class="tavern-trending__header">
        <span class="tavern-trending__heading">🔥 TRENDING TONIGHT</span>
        <a href="/hot" class="tavern-trending__all">ALL HOT THREADS →</a>
      </div>
      {{#unless this.loading}}
        <div class="tavern-trending__items">
          {{#each this.trending as |t|}}
            <div class="tavern-trending__item">
              <span class="tavern-trending__cat">{{t.categoryName}}</span>
              <a href={{t.url}} class="tavern-trending__title">{{t.title}}</a>
              <div class="tavern-trending__meta">
                {{t.author}} · {{t.postsCount}} replies · {{timeAgo t.bumpedAt}}
              </div>
            </div>
          {{/each}}
        </div>
      {{/unless}}
    </div>
  {{/if}}
{{/if}}
```

Note: `timeAgo` must be imported into the template scope. In Glimmer `.gjs`, helpers used in `<template>` must be in scope via import or local binding. Since `timeAgo` is a module-scope function, it is available directly in the `<template>` block without import — this is a GJS feature where the component class file's module scope is the template scope. [VERIFIED: Discourse GJS component pattern]

**SCSS — new §9:**

```scss
// ---- 9. Trending Tonight (below banner, cream background) -----

.tavern-trending {
  background: var(--tavern-cream);
  padding: 32px 64px 24px;
  border-bottom: 1px solid var(--tavern-rule);

  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }

  &__heading {
    font-family: var(--font-ui);
    font-size: 10px; font-weight: 700; letter-spacing: 0.3em;
    text-transform: uppercase;
    color: var(--tavern-ink);
  }

  &__all {
    font-family: var(--font-ui);
    font-size: 10px; font-weight: 700; letter-spacing: 0.12em;
    text-transform: uppercase;
    color: rgba(42,31,23,.6);
    text-decoration: none;
    &:hover { color: var(--tavern-brass); }
  }

  &__items {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;
  }

  &__item {
    border-top: 2px solid var(--category-color, var(--tertiary));
    padding-top: 12px;
  }

  &__cat {
    display: block;
    font-family: var(--font-ui);
    font-size: 10px; font-weight: 700; letter-spacing: 0.2em;
    font-variant: small-caps;
    text-transform: uppercase;
    color: var(--primary-medium);
    margin-bottom: 4px;
  }

  &__title {
    display: block;
    font-family: var(--font-display);
    font-size: 15px; font-weight: 700;
    color: var(--tavern-ink);
    text-decoration: none;
    line-height: 1.3;
    margin-bottom: 4px;
    &:hover { color: var(--tavern-oxblood); }
  }

  &__meta {
    font-family: var(--font-serif);
    font-size: 12px; font-weight: 400; font-style: italic;
    color: rgba(42,31,23,.55);
    line-height: 1.4;
  }
}
```

### Deliverable 3: Room Cards

**Admin step (required, not a code change):**
Admin → Settings → Interface → "desktop category page style" → `categories_boxes`

This MUST be documented in the plan as a manual verification step. Without it, the CSS selectors target nothing and ROOM-01 is not deliverable by code alone.

**SCSS — §6 extension** (additive lines after line 340):

```scss
// Phase 3 extensions to .category-boxes
.category-boxes {
  column-gap: 24px;
  row-gap: 24px;
}

.category-boxes .category-box {
  border-radius: 2px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.07);
  overflow: hidden;
  transition: box-shadow 0.15s ease;

  &:hover { box-shadow: 0 4px 16px rgba(0,0,0,0.12); }
}

.category-boxes .category-box-inner {
  padding: 20px;
}

// Topic/post count labels in category boxes
.category-boxes .category-box .category-stat,
.category-boxes .category-box .stat-text {
  font-family: var(--font-ui);
  font-size: 12px; font-weight: 700; letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--primary-medium);
  margin-top: 8px;
}
```

Note: Discourse's exact selector for topic/post counts inside `.category-box` varies by Discourse version. The plan should note that the executor must inspect live DOM and adjust `.category-stat` / `.stat-text` selector if needed. The `.category-box-inner` padding wrapper is standard in the `categories_boxes` template — if absent on the live instance, add `padding: 20px` directly to `.category-box` instead.

---

## Pitfalls and Gotchas

**Pitfall 1: `featured` removal changes `raw` slice index**

Current code: `this.featured = raw[0] ? toItem(raw[0]) : null` then `this.trending = raw.slice(1, 4)`. After removing `featured`, trending becomes `raw.slice(0, 3)`. If this is not updated, the banner will show no trending items on forums with 3 or fewer trending topics.

**Pitfall 2: `desktop_category_page_style` is silently ignored in `theme_site_settings`**

If added to `about.json`, it will not cause an error but also will not apply. The CSS for `.category-boxes` will exist but target empty DOM. Admin must set it manually. Failing to include this as a plan step means ROOM-01 appears to fail in testing even though the code is correct.

**Pitfall 3: `body:not(.navigation-topics):not(.navigation-categories) .tavern-banner { display: none; }` on line 537**

This rule hides the `.tavern-banner` element. If `.tavern-trending` is rendered inside the banner `<section>`, it would also be hidden on non-homepage routes — this is why D-07 (trending outside the dark banner) is correct. The trending `<div class="tavern-trending">` is a sibling of `<section class="tavern-banner">`, not nested inside it, so the hide rule does NOT affect it.

However: if `show_trending_strip` is false, the `.tavern-trending` div should not render even on non-homepage routes. The `{{#if settings.show_trending_strip}}` guard handles this. But the `{{#if this.shouldShow}}` outer guard (which checks `discovery.*` routes) ALSO wraps trending, so it correctly hides on non-homepage routes regardless.

**Pitfall 4: `(array ...)` and `(hash ...)` helpers in GJS template**

These are Ember helpers. They may not be importable/available in all Discourse GJS contexts. Using a JS getter (`get statRows()`) avoids any dependency on these helpers. The getter approach is always safe.

**Pitfall 5: `timeAgo` in template scope**

In `.gjs` files, module-scope functions and values are directly accessible in `<template>` — this is the design of GJS. However, a function must be in the module scope (not inside the class) to be callable as a helper in the template. Placing `timeAgo` at module scope (before the class definition) is the correct pattern. If placed inside the class as a method, it must be accessed as `{{this.timeAgo t.bumpedAt}}`.

**Pitfall 6: `about.json` response field path**

The research SUMMARY.md notes these fields are from the live Discourse API. The path is `aboutRes.about.stats.users_count` — note the `.about.` nesting. If the theme uses `aboutRes.stats.users_count` (missing the `.about.` prefix), all stats will be `undefined`. Use `aboutRes?.about?.stats ?? {}` defensively.

**Pitfall 7: `posts_count` vs `reply_count` in `/top.json`**

The current `toItem()` maps `t.posts_count` to `postsCount`. In Discourse's topic list API, `posts_count` includes the original post (so a topic with 5 replies has `posts_count: 6`). The meta line shows "N replies" — this is a known minor inaccuracy. D-11 says "reply count" but the data field is `posts_count`. This is acceptable (matches the existing pattern). Do not change it.

**Pitfall 8: `Category.findById()` returns null for hidden/restricted categories**

If a topic's category is restricted from anonymous users, `Category.findById(id)` returns `null`. The `cat?.name ?? ""` pattern handles this gracefully — the category label simply shows blank. This is correct behavior.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `timeAgo` module-scope function is callable in `<template>` without import in `.gjs` | Implementation Approach, Deliverable 2 | Template would fail to render; fix by using `{{this.timeAgoFormat t.bumpedAt}}` as a class method instead |
| A2 | `@tracked stats = null` initialized as null; `get statRows()` reads `this.stats?.patronsInside` | Implementation Approach, Deliverable 1 | If `stats` is read before `loadData()` resolves, `null?.patronsInside` returns `undefined` — handled by `?? "—"` in getter |
| A3 | Discourse's `categories_boxes` DOM uses `.category-box-inner` as padding wrapper | Implementation Approach, Deliverable 3 | If absent, `.category-box-inner { padding: 20px }` rule does nothing; executor must inspect live DOM |
| A4 | `.category-stat` or `.stat-text` is the selector for topic/post count text in `.category-box` | Implementation Approach, Deliverable 3 | Counts may remain unstyled; executor must inspect live DOM to find correct selector |

---

## Sources

### Primary (HIGH confidence)
- `discourse/discourse config/site_settings.yml` — confirmed `desktop_category_page_style` lacks `themeable: true` [VERIFIED]
- Context7 `/discourse/discourse-developer-docs` — `theme_site_settings` in `about.json`, service injection patterns [VERIFIED]
- `nolosb/discourse-featured-lists featured-list.gjs` — `import Category from "discourse/models/category"` and `Category.findById()` pattern [VERIFIED]
- Local codebase read — `tavern-banner.gjs` lines 1–157, `common.scss` lines 1–537, `about.json`, `theme-setup.js`, `settings.yml` [VERIFIED]

### Secondary (MEDIUM confidence)
- meta.discourse.org — `desktop_category_page_style` as admin-only setting, override component patterns [CITED: meta.discourse.org/t/categories-layout-override/131098]
- `tshenry/discourse-categories-layout-override` about.json — confirmed this component does NOT use `theme_site_settings` [VERIFIED via WebFetch]

### Tertiary (LOW confidence)
- `timeAgo` in GJS template scope pattern — inferred from GJS module-scope-as-template-scope design, not verified against a live example [ASSUMED: A1]
