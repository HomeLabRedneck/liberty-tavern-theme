# Phase 3: Homepage Content — Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 2 (both are modifications to existing files, no new files)
**Analogs found:** 2 / 2 (each file is its own analog — pattern extraction from current state)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `javascripts/discourse/components/tavern-banner.gjs` | component | request-response + CRUD | itself (current state is the base) | self-reference |
| `common/common.scss` | style | transform | itself (current state is the base) | self-reference |

Both files are being surgically modified — not created. The pattern to follow is the file's existing code. The analog IS the file.

---

## Pattern Assignments

### `javascripts/discourse/components/tavern-banner.gjs`

**File:** `javascripts/discourse/components/tavern-banner.gjs`

**Imports pattern** (lines 1–7) — keep all of these, add `Category` import:

```js
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
// ADD: import Category from "discourse/models/category";
```

**`@tracked` property pattern** (lines 14–17) — the writable reactive state surface:

```js
@tracked trending = [];
@tracked featured = null;   // DELETE in Phase 3
@tracked badges = [];        // DELETE in Phase 3
@tracked loading = true;
// ADD in Phase 3: @tracked stats = null;
```

Rule: every piece of data the template reads reactively must be a `@tracked` property. Setting `this.stats = { ... }` in `loadData()` automatically triggers re-render — no manual notification needed.

**`shouldShow` getter pattern** (lines 23–27) — route-detection guard:

```js
get shouldShow() {
  if (!settings.show_homepage_banner) return false;
  const route = this.router.currentRouteName || "";
  return /^discovery\./.test(route);
}
```

This getter gates the entire component render. Phase 3 expands the `{{#if this.shouldShow}}` block in the template to wrap BOTH `<section class="tavern-banner">` and the new `<div class="tavern-trending">` sibling.

**`showBadges` getter pattern** (lines 29–31) — DELETE this in Phase 3, copy the structural pattern for the `statRows` getter:

```js
// Current (DELETE):
get showBadges() {
  return settings.show_badges_card && this.badges.length > 0;
}

// New statRows getter follows same structural pattern — a getter that
// derives an array for {{#each}} in the template:
get statRows() {
  return [
    { label: "Patrons Inside", value: this.stats?.patronsInside ?? "—" },
    { label: "Members",        value: this.stats?.members        ?? "—" },
    { label: "Posts Today",    value: this.stats?.postsToday     ?? "—" },
    { label: "Open Rooms",     value: this.stats?.openRooms      ?? "—" },
  ];
}
```

**Constructor pattern** (lines 33–36) — unchanged, copy as-is:

```js
constructor() {
  super(...arguments);
  if (settings.show_homepage_banner) this.loadData();
}
```

**`openNewTopic` action** (lines 38–45) — unchanged, copy as-is:

```js
@action
openNewTopic() {
  if (this.currentUser) {
    this.composer.openNewTopic({});
  } else {
    this.router.transitionTo("login");
  }
}
```

**`loadData()` current structure** (lines 47–93) — THIS IS THE BASE FOR REFACTORING:

```js
async loadData() {
  try {
    const period = settings.trending_period || "daily";
    let topRes = await ajax(`/top.json?period=${period}`).catch(() => null);
    let raw = topRes?.topic_list?.topics || [];
    if (raw.length < 4) {
      const latestRes = await ajax("/latest.json").catch(() => null);
      const latest = latestRes?.topic_list?.topics || [];
      const seen = new Set(raw.map((t) => t.id));
      for (const t of latest) {
        if (!seen.has(t.id)) { raw.push(t); seen.add(t.id); }
        if (raw.length >= 4) break;
      }
    }

    const toItem = (t) => ({           // <-- MOVE to module scope, EXTEND fields
      id: t.id,
      title: htmlSafe(t.fancy_title ?? t.title ?? ""),
      url: `/t/${t.slug}/${t.id}`,
      postsCount: t.posts_count,
      views: t.views,                  // DROP: no longer used in template
      likeCount: t.like_count,         // DROP: no longer used in template
    });

    this.featured = raw[0] ? toItem(raw[0]) : null;  // DELETE
    this.trending = raw.slice(1, 4).map(toItem);      // CHANGE to raw.slice(0, 3)

    const badgeRes = await ajax("/badges.json").catch(() => null); // DELETE entire badges block
    if (badgeRes?.badges) { ... }
  } catch (e) {
    console.warn("Liberty Tavern banner: failed to load data", e);
  } finally {
    this.loading = false;              // KEEP: always in finally block
  }
}
```

Key changes to `loadData()`:
- Replace sequential `await` with `Promise.all(["/top.json", "/about.json"])` — see Research §5
- Remove `/badges.json` fetch entirely
- Change `raw.slice(1, 4)` to `raw.slice(0, 3)` (featured no longer consumes `raw[0]`)
- Set `this.stats = { ... }` from `aboutRes?.about?.stats` before `this.loading = false`
- Fallback padding logic (lines 52–60) is KEPT — the `raw.length < 4` threshold becomes `< 3`

**`toItem()` current code** (lines 62–69) — move to module scope, extend:

```js
// Current (inside loadData, 6 fields):
const toItem = (t) => ({
  id: t.id,
  title: htmlSafe(t.fancy_title ?? t.title ?? ""),
  url: `/t/${t.slug}/${t.id}`,
  postsCount: t.posts_count,
  views: t.views,
  likeCount: t.like_count,
});

// Phase 3 (module scope, above class, 5 fields — views and likeCount dropped):
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

**Template: outer `{{#if this.shouldShow}}` guard** (lines 96–155) — expand to wrap sibling elements:

```hbs
<template>
  {{#if this.shouldShow}}
    <section class="tavern-banner">
      ...
    </section>

    {{#if this.settings.show_trending_strip}}
      <div class="tavern-trending">
        ...
      </div>
    {{/if}}
  {{/if}}
</template>
```

GJS allows multiple root siblings inside `<template>` — no wrapper `<div>` needed at the top level.

**Template: `tavern-banner__aside` current structure** (lines 122–152) — replace contents only, keep wrapper:

```hbs
{{!-- Current content to DELETE: --}}
<aside class="tavern-banner__aside">
  {{#if this.featured}}
    <div class="tavern-banner__feature"> ... </div>
  {{/if}}
  {{#if this.showBadges}}
    <div class="tavern-banner__badges"> ... </div>
  {{/if}}
</aside>

{{!-- Phase 3 replacement (keep <aside> wrapper, replace children): --}}
<aside class="tavern-banner__aside">
  <div class="tavern-banner__stats">
    <div class="label">TONIGHT AT THE HOUSE</div>
    {{#each this.statRows as |row|}}
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

**Template: `tavern-banner__trending` current block** (lines 105–119) — DELETE this block entirely. It becomes the new `.tavern-trending` sibling OUTSIDE `<section class="tavern-banner">`.

**Module-scope `timeAgo` function** — new, placed above the class definition:

```js
function timeAgo(isoString) {
  if (!isoString) return "";
  const diff = Math.floor((Date.now() - new Date(isoString).getTime()) / 1000);
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  return `${Math.floor(diff / 86400)}d`;
}
```

In GJS, module-scope functions are in template scope — call as `{{timeAgo t.bumpedAt}}` directly. If that fails at runtime, fall back to a class method: `{{this.timeAgo t.bumpedAt}}`.

---

### `common/common.scss`

**File:** `common/common.scss`

**§6 existing category styles** (lines 323–340) — BASE TO EXTEND, do not replace:

```scss
// ---- 6. Categories (.category-list / .category-boxes) -------

.category-list .category, .category-boxes .category-box {
  border-left: 4px solid var(--category-color, var(--tertiary));
  background: var(--secondary);

  .category-title-link h3 {
    font-family: var(--font-display);
    font-style: italic;
    font-weight: 900;
    font-size: 22px;
  }
  .category-description {
    font-family: var(--font-serif);
    font-size: 14px;
    color: var(--primary-medium);
  }
}
```

Phase 3 adds new rules AFTER line 340 (additive only — do not touch the existing block).

**§6 `.badge-category__wrapper` block** (lines 342–355) — NO CHANGE, shown here for context:

```scss
// Category badge as filled circle with letter
.badge-category__wrapper .badge-category {
  background: transparent !important;
  position: relative;
  padding-left: 22px;
  &::before {
    content: '';
    position: absolute; left: 0; top: 50%;
    width: 16px; height: 16px;
    border-radius: 50%;
    background: var(--category-badge-color);
    transform: translateY(-50%);
  }
}
```

**§8 blocks to DELETE** — these five blocks in `.tavern-banner { }` (lines 441–531) are fully removed in Phase 3. Planner should reference exact line ranges so the executor knows what to delete:

- `&__feature` block: lines 441–458
- `&__feature-link` block: lines 460–463
- `&__feature-title` block: lines 465–471
- `&__trending` block: lines 473–498
- `&__badges` block: lines 500–531

**§8 blocks to PRESERVE** — inside `.tavern-banner { }`, keep everything EXCEPT the five blocks above:

- Lines 375–386: `.tavern-banner` root rule (background gradient, padding, border-bottom, font-family)
- Lines 388–395: `section.tavern-banner::before` ribbon (CRITICAL — do not delete)
- Lines 397–439: `&__grid`, `&__title`, `&__subtitle`, `&__cta`, `&__cta--ghost` — all unchanged
- Line 537: `body:not(.navigation-topics):not(.navigation-categories) .tavern-banner { display: none; }` — PRESERVED

**§8 `&__feature` block pattern** (lines 441–458) — copy THIS STRUCTURE for the new `&__stats` block that replaces it:

```scss
// Current __feature pattern to use as structural template for new __stats:
&__feature {
  background: rgba(255,255,255,.05);
  color: #f5ebd9;
  padding: 24px;
  border-radius: 2px;
  border: 1px solid var(--tavern-brass);
  box-shadow: 0 8px 24px rgba(0,0,0,0.4);

  .label {
    font-family: var(--font-ui);
    font-size: 9px; letter-spacing: 0.3em; font-weight: 700;
    color: var(--tavern-brass); text-transform: uppercase;
  }
  // ... inner stats grid ...
}
```

**§8 `&__trending` block pattern** (lines 473–498) — DELETE this; the structure informs the new §9 `.tavern-trending`:

```scss
// Current &__trending (DELETE — pattern reference only):
&__trending {
  margin-top: 40px; padding-top: 24px;
  border-top: 1px solid rgba(245, 235, 217, .15);

  .heading {
    font-family: var(--font-display);
    font-style: italic; font-weight: 700;
    font-size: 13px; color: var(--tavern-brass);
    text-transform: uppercase; letter-spacing: 0.16em;
    margin-bottom: 14px;
    &::before { content: '✦ '; color: var(--tavern-brass); }
  }
  .items { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
  .item {
    font-family: var(--font-serif);
    a {
      font-family: var(--font-display);
      font-weight: 700; font-size: 15px;
      color: #f5ebd9; text-decoration: none;
      line-height: 1.3; display: block; margin-bottom: 6px;
      &:hover { color: var(--tavern-brass); }
    }
    .meta { font-size: 12px; color: rgba(245,235,217,.6); font-style: italic; }
  }
}
```

---

## Shared Patterns

### `@tracked` + `loadData()` initialization guard
**Source:** `tavern-banner.gjs` lines 14–17, 33–36
**Apply to:** all new `@tracked` properties (`stats`)

```js
// Pattern: declare all reactive state at top of class
@tracked stats = null;   // null = not yet loaded; template uses ?. safely

// Pattern: load only when the feature is enabled
constructor() {
  super(...arguments);
  if (settings.show_homepage_banner) this.loadData();
}
```

### `finally` loading flag
**Source:** `tavern-banner.gjs` lines 88–92
**Apply to:** `loadData()` refactor — `this.loading = false` MUST stay in `finally`

```js
} catch (e) {
  console.warn("Liberty Tavern banner: failed to load data", e);
} finally {
  this.loading = false;   // always fires, even if Promise.all rejects
}
```

### `.catch(() => null)` per-fetch error isolation
**Source:** `tavern-banner.gjs` line 50
**Apply to:** each `ajax()` call inside `Promise.all()`

```js
// Pattern: individual fetch failures do not abort sibling fetches
const [topRes, aboutRes] = await Promise.all([
  ajax(`/top.json?period=${period}`).catch(() => null),
  ajax("/about.json").catch(() => null),
]);
// Both calls get null on failure; downstream code uses ?. and ?? "—" guards
```

### BEM `&__modifier` nesting pattern
**Source:** `common.scss` lines 399–531 (entire `.tavern-banner { }` nested block)
**Apply to:** new `&__stats`, `&__stat-row`, `&__stat-label`, `&__stat-num` blocks

```scss
// Pattern: all banner sub-elements are BEM modifiers inside the parent block
.tavern-banner {
  &__grid { ... }
  &__title { ... }
  // New blocks follow same nesting:
  &__stats { ... }
  &__stat-row { ... }
  &__stat-label { ... }
  &__stat-num {
    ...
    &--loading { opacity: 0.4; }  // BEM modifier for loading state
  }
}
```

### `{{#unless this.loading}}` template guard
**Source:** `tavern-banner.gjs` lines 108–117
**Apply to:** stats panel numbers and trending items — show `—` placeholder while loading

```hbs
{{!-- Pattern: loading guard around dynamic content --}}
{{#unless this.loading}}
  <div class="items">
    {{#each this.trending as |t|}}
      ...
    {{/each}}
  </div>
{{/unless}}
```

### CSS `::before`/`::after` decoration pattern
**Source:** `common.scss` lines 342–354 (`.badge-category__wrapper` circle), lines 389–395 (ribbon)
**Apply to:** `&__stats` corner brackets (new `::before`/`::after` pseudo-elements)

```scss
// Pattern: pseudo-elements for decorative content, absolute-positioned
section.tavern-banner::before {
  content: '✦ WELCOME, FRIEND ✦';
  position: absolute; top: 24px; left: 64px;
  font-family: var(--font-ui);
  ...
}
// New corner-bracket pattern follows same absolute positioning approach
&__stats {
  position: relative;
  &::before {
    content: '';
    position: absolute; top: -1px; left: -1px;
    width: 10px; height: 10px;
    border-top: 2px solid var(--tavern-brass);
    border-left: 2px solid var(--tavern-brass);
  }
}
```

---

## No Analog Found

No files in Phase 3 lack a codebase analog. Both modified files serve as their own base pattern. The new `.tavern-trending` standalone section is a structural variant of the existing `&__trending` BEM block (which it replaces) — same grid/item/meta structure, new BEM root class, cream background instead of dark.

---

## Metadata

**Files scanned:** 2 source files read directly
**Analog search scope:** `javascripts/discourse/components/tavern-banner.gjs`, `common/common.scss` lines 320–537
**Pattern extraction date:** 2026-04-28
**Key line references:**
- `tavern-banner.gjs` lines 1–157 (complete file, 157 lines)
- `common.scss` lines 323–340 (§6 category boxes)
- `common.scss` lines 342–355 (§6 badge circle)
- `common.scss` lines 375–395 (§8 banner root + ribbon)
- `common.scss` lines 397–439 (§8 banner sub-elements to keep)
- `common.scss` lines 441–531 (§8 blocks to DELETE: feature, feature-link, feature-title, trending, badges)
- `common.scss` line 537 (hide rule to preserve)
