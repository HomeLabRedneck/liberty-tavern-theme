---
phase: 01-foundation-repair
reviewed: 2026-04-26T23:55:48Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - javascripts/discourse/api-initializers/theme-setup.js
  - about.json
  - javascripts/discourse/components/tavern-banner.js
  - javascripts/discourse/components/tavern-banner.hbs
  - javascripts/discourse/api-initializers/honored-patrons.js
  - common/common.scss
  - settings.yml
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-04-26T23:55:48Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Seven Phase 1 source files were reviewed at standard depth. The architecture is
sound: correct outlet name (`discovery-list-container-top`), correct composer
service usage, correct `@tracked` reactivity, and no banned patterns
(`appEvents.trigger("sidebar:refresh")`, `@import` for Google Fonts,
`common/header.html`, inline `style=`, `/new-topic` links) were found.

Five warnings surface real runtime risks: a missing `loading` indicator leaves
the trending strip blank-but-interactive during fetch; a double-guard on
`shouldShow` wastes one API round-trip on every non-homepage route; the
`I18n.t` call in the sidebar will throw on Discourse versions that have
migrated to `i18n.t`; `topicUrl` silently produces broken links when
`topic.slug` is missing; and the CSS route-hiding rule misfires because
`archetype-regular` is a topic-level body class, not a homepage guard.

Four info items cover: placeholder URLs in `about.json`; a missing `<loading>`
branch in the HBS template; magic color values duplicated between SCSS and the
colour scheme in `about.json`; and an unused `@tracked` import in
`honored-patrons.js`.

---

## Warnings

### WR-01: `loadData()` fires on every route before `shouldShow` is checked

**File:** `javascripts/discourse/components/tavern-banner.js:36`
**Issue:** The constructor calls `if (this.shouldShow) this.loadData()` — but
`this.router.currentRouteName` may not be populated synchronously during the
first render cycle in Glimmer. If the route name is `undefined` at construction
time the regex `/^discovery\./.test("")` returns `false`, causing `loadData()`
to be skipped entirely and leaving `loading = true` forever with a permanently
blank trending strip.

Conversely, `shouldShow` in the template (line 1 of the HBS) is checked
reactively each render, so the guard is redundant in the constructor if the
template already gates on it — and harmful if it fires before the router is
ready.

**Fix:** Remove the guard from the constructor; let the template's `{{#if
this.shouldShow}}` prevent rendering, and trigger the load via a modifier or
`didInsert` hook so the router is definitely settled:

```js
// constructor — just kick off the load unconditionally
constructor() {
  super(...arguments);
  this.loadData();
}
```

Alternatively, use `scheduleOnce('afterRender', this, this.loadData)` from
`@ember/runloop` to ensure the router is settled before checking the route.

---

### WR-02: `loading` state never reflected in the HBS — user sees empty content during fetch

**File:** `javascripts/discourse/components/tavern-banner.hbs:13`
**Issue:** The `{{#unless this.loading}}` block hides trending items while data
loads, but there is no corresponding skeleton or loading placeholder. During the
fetch window the right-column feature card and badges card are also absent
(gated by `{{#if this.featured}}` and `{{#if this.showBadges}}`). The banner
renders its title and CTA buttons but the data areas are blank. On a slow
connection this looks like a layout bug.

This is classified as a warning (not info) because Discourse renders
synchronously on first paint — users on slow connections will see a collapsed
aside column with no height.

**Fix:** Add a minimal loading placeholder inside the `unless` guard:

```hbs
{{#unless this.loading}}
  <div class="items"> ... </div>
{{else}}
  <div class="tavern-banner__loading" aria-busy="true">Loading…</div>
{{/unless}}
```

And add the corresponding aside guard:

```hbs
{{#if this.loading}}
  <div class="tavern-banner__aside-skeleton"></div>
{{else}}
  {{#if this.featured}}…{{/if}}
{{/if}}
```

---

### WR-03: `I18n.t` may be undefined in newer Discourse versions

**File:** `javascripts/discourse/api-initializers/honored-patrons.js:58`
**Issue:** The sidebar section title uses the global `I18n.t(...)`. Discourse
3.3+ has migrated from the `I18n` global to the `i18n` import from
`discourse-i18n`. When the global is removed the sidebar section will throw a
`ReferenceError: I18n is not defined` at runtime, crashing the entire sidebar
section.

```js
get title() { return I18n.t(themePrefix("liberty_tavern.sidebar.honored_patrons")); }
```

**Fix:** Import from `discourse-i18n` (the canonical Discourse 3.2+ import):

```js
import { i18n } from "discourse-i18n";
// ...
get title() { return i18n(themePrefix("liberty_tavern.sidebar.honored_patrons")); }
```

If backward compatibility with Discourse < 3.2 is required, use a safe
fallback:

```js
const t = (typeof I18n !== "undefined") ? I18n.t.bind(I18n) : (key) => key;
get title() { return t(themePrefix("liberty_tavern.sidebar.honored_patrons")); }
```

---

### WR-04: `topicUrl` produces broken links when `topic.slug` is absent

**File:** `javascripts/discourse/components/tavern-banner.js:103`
**Issue:** `/t/${topic.slug}/${topic.id}` — if `topic.slug` is `null` or
`undefined` (can happen for some system topics or topics returned from
`/badges.json` adjacent calls), the URL becomes `/t/undefined/42`, which
returns a 404 in Discourse.

```js
topicUrl = (topic) => `/t/${topic.slug}/${topic.id}`;
```

**Fix:** Guard against a missing slug:

```js
topicUrl = (topic) => {
  const slug = topic.slug || topic.id;
  return `/t/${slug}/${topic.id}`;
};
```

Discourse itself treats `/t/topic-slug/42` and `/t/42` equivalently when the
ID is present, so falling back to the ID alone is safe.

---

### WR-05: CSS route-hiding rule is incorrect — uses topic-level body class as homepage guard

**File:** `common/common.scss:404-405`
**Issue:** The rule intended to hide the banner on non-homepage routes is:

```scss
body:not(.navigation-topics):not(.navigation-categories):not(.archetype-regular) .tavern-banner,
body.archetype-regular .tavern-banner { display: none; }
```

`.archetype-regular` is applied to `<body>` when viewing a regular *topic*, not
on the homepage. The intent appears to be: "hide the banner on topic pages." But
the logic is inverted in the second clause — `body.archetype-regular
.tavern-banner { display: none; }` correctly hides the banner on topic pages,
but the first clause `body:not(.archetype-regular)` *also* includes the homepage
routes (`.navigation-topics`, `.navigation-categories`). The `:not()`
conjunction means the banner is only shown when **all three** classes are
present simultaneously, which never happens.

In practice the CSS guard is redundant because the template already gates on
`{{#if this.shouldShow}}`, but if the component mounts on a topic page before
the route guard fires, the banner could flash briefly before being hidden by
SCSS — or if the route guard fails (see WR-01), the SCSS rule is the only
fallback, and it is broken.

**Fix:** Simplify to a single clean hide rule:

```scss
// Hide banner everywhere except homepage routes
body:not(.navigation-topics):not(.navigation-categories) .tavern-banner {
  display: none;
}
```

---

## Info

### IN-01: Placeholder URLs in `about.json` will expose stub links on Theme Details page

**File:** `about.json:3-4`
**Issue:** Both `about_url` and `license_url` contain `your-org` placeholder
GitHub paths. Discourse displays these on the theme details page visible to
admins.

```json
"about_url": "https://github.com/your-org/liberty-tavern-theme",
"license_url": "https://github.com/your-org/liberty-tavern-theme/blob/main/LICENSE"
```

**Fix:** Replace with the real repository URL or remove the fields if the theme
is not publicly hosted.

---

### IN-02: Unused `@tracked` import in `honored-patrons.js`

**File:** `javascripts/discourse/api-initializers/honored-patrons.js:3`
**Issue:** `import { tracked } from "@glimmer/tracking"` is at the module scope
(line 3), but `@tracked` is used inside the anonymous class returned from
`api.addSidebarSection()`. In a standard ES module / Babel pipeline, decorator
imports at module scope are correctly available to inner classes — so this is
not a functional bug. However, the import is at the *initializer* level while
the decorator is applied inside the section factory, which can confuse static
analysis tools and may trigger "unused import" lint warnings depending on the
build config.

No change strictly required, but it is cleaner to note the implicit scoping
dependency.

---

### IN-03: Magic color values duplicated between SCSS and `about.json`

**File:** `common/common.scss:8, 9, 17` / `about.json:8-10`
**Issue:** Hard-coded hex values like `#2a1f17`, `#f5ebd9`, `#7a1f1f` appear
both in `:root` custom property declarations (SCSS) and in the color scheme
object (`about.json`). If the `about.json` color scheme values are changed via
Discourse's admin UI, the SCSS hard-coded values will diverge. This is an
expected Discourse limitation (color schemes set CSS vars; SCSS runs at build
time), but it is worth noting that SCSS rules referencing `--secondary`,
`--tertiary`, etc. will correctly track admin overrides, while the hard-coded
hex values (`color: #2a1f17`) will not.

**Fix (low priority):** Prefer CSS variable references over hard-coded hex in
SCSS where possible:

```scss
// Instead of:
color: #2a1f17;
// Use:
color: var(--primary);
```

---

### IN-04: No translation key stub for `liberty_tavern.sidebar.honored_patrons`

**File:** `javascripts/discourse/api-initializers/honored-patrons.js:58`
**Issue:** `themePrefix("liberty_tavern.sidebar.honored_patrons")` expects a
locale file entry. No `en.yml` or equivalent translation file was included in
the reviewed file list. If the key is missing from the locale file, Discourse
will render the raw key string (e.g., `"theme_xx.liberty_tavern.sidebar.honored_patrons"`) 
as the section header, which is jarring.

**Fix:** Confirm that a `config/locales/client.en.yml` exists with:

```yaml
en:
  js:
    liberty_tavern:
      sidebar:
        honored_patrons: "Honored Patrons"
```

Or fall back to a hard-coded string to avoid the dependency:

```js
get title() { return "Honored Patrons"; }
```

---

_Reviewed: 2026-04-26T23:55:48Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
