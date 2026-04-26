# Phase 1: Foundation Repair — Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 6 (5 modified + 1 new + 1 deleted)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `javascripts/discourse/api-initializers/theme-setup.js` (NEW) | api-initializer | request-response | `javascripts/discourse/api-initializers/honored-patrons.js` | exact |
| `javascripts/discourse/components/tavern-banner.js` | component | request-response + async fetch | self (existing, being modified) | exact |
| `javascripts/discourse/components/tavern-banner.hbs` | template | request-response | self (existing, being modified) | exact |
| `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` | connector | — | — | DELETE — no analog needed |
| `javascripts/discourse/api-initializers/honored-patrons.js` | api-initializer | async fetch + reactive | self (existing, being modified) | exact |
| `about.json` | config | — | self (existing, being modified) | exact |
| `common/common.scss` | stylesheet | — | self (existing, being modified) | exact |

---

## Pattern Assignments

### `javascripts/discourse/api-initializers/theme-setup.js` (NEW — api-initializer, request-response)

**Analog:** `javascripts/discourse/api-initializers/honored-patrons.js`

**Imports pattern** (honored-patrons.js lines 1–2):
```js
import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
```
For theme-setup.js, only `apiInitializer` and the component import are needed — no `ajax`:
```js
import { apiInitializer } from "discourse/lib/api";
import TavernBanner from "../components/tavern-banner";
```

**Core initializer structure** (honored-patrons.js lines 4–5):
```js
export default apiInitializer("1.13.0", (api) => {
  if (!settings.honored_patrons_enabled) return;
  // ...
});
```
Apply same guard for the banner setting:
```js
export default apiInitializer("1.13.0", (api) => {
  if (!settings.show_homepage_banner) return;
  api.renderInOutlet("discovery-list-container-top", TavernBanner);
});
```

**No error handling needed** — `api.renderInOutlet` is synchronous and Discourse swallows render errors internally.

---

### `javascripts/discourse/components/tavern-banner.js` (component, request-response + async fetch)

**Analog:** self — full file read above. Two targeted changes only.

**Change 1 — `shouldShow` route check** (lines 27–31):

Current code:
```js
get shouldShow() {
  if (!settings.show_homepage_banner) return false;
  const route = this.router.currentRouteName || "";
  return /^discovery\./.test(route);
}
```
Replace regex with `defaultHomepage()` if available; keep regex as fallback. Pattern: check for function existence before calling.
```js
get shouldShow() {
  if (!settings.show_homepage_banner) return false;
  const route = this.router.currentRouteName || "";
  // defaultHomepage() is available in Discourse 3.1+ via discourse/lib/utilities
  // Fall back to regex if not available (older builds)
  try {
    const { defaultHomepage } = await import("discourse/lib/utilities");
    return route === `${defaultHomepage()}.index` || route.startsWith(`${defaultHomepage()}.`);
  } catch {
    return /^discovery\./.test(route);
  }
}
```
NOTE: `shouldShow` is a sync getter called in `constructor`. The simpler resolution (confirmed by SUMMARY.md) is to keep the regex — `defaultHomepage()` is not reliably importable in a sync getter without side effects. Decision per CONTEXT.md D-01 discretion: keep `/^discovery\./` regex as-is. No change required to `shouldShow`.

**Change 2 — Add `@service composer` and `@service router` (router already present)**

Current service declarations (lines 9–10):
```js
@service router;
@service site;
```
Add composer:
```js
@service router;
@service site;
@service composer;
```

**Change 3 — CTA action method** (new, after existing service declarations):
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
Requires adding `@action` import:
```js
import { action } from "@ember/object";
```
And `currentUser` service:
```js
@service currentUser;
```

**Existing tracked fields pattern** (lines 12–15) — unchanged, reference only:
```js
@tracked trending = [];
@tracked badges = [];
@tracked featured = null;
@tracked loading = true;
```

**Error handling pattern** (lines 79–83) — unchanged, reference only:
```js
} catch (e) {
  console.warn("Liberty Tavern banner: failed to load data", e);
} finally {
  this.loading = false;
}
```

---

### `javascripts/discourse/components/tavern-banner.hbs` (template, request-response)

**Analog:** self — full file read above. Two targeted changes.

**Change 1 — Replace `/new-topic` anchor with button** (line 7):

Current:
```hbs
<a href="/new-topic" class="tavern-banner__cta">Pull a stool</a>
```
Replace with:
```hbs
<button type="button" class="tavern-banner__cta" {{on "click" this.openNewTopic}}>Pull a stool</button>
```

**Change 2 — Remove inline styles from feature link** (lines 34–36):

Current:
```hbs
<a href={{this.topicUrl this.featured}} style="color:inherit;text-decoration:none;">
  <h3 style="font-family:var(--font-display);font-style:italic;font-weight:900;font-size:24px;margin:8px 0 4px;">
    {{this.featured.fancy_title}}
  </h3>
</a>
```
Replace with BEM classes (no inline styles):
```hbs
<a href={{this.topicUrl this.featured}} class="tavern-banner__feature-link">
  <h3 class="tavern-banner__feature-title">
    {{this.featured.fancy_title}}
  </h3>
</a>
```

---

### `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` (DELETE)

**Action:** Delete this file. It contains only `<TavernBanner />` (line 1). After deletion, the banner is mounted exclusively via `api.renderInOutlet` in `theme-setup.js`. No analog needed — this file should not exist after Phase 1.

---

### `javascripts/discourse/api-initializers/honored-patrons.js` (api-initializer, async fetch + reactive)

**Analog:** self — full file read above. Two targeted changes.

**Change 1 — Replace `_patrons` non-tracked field with `@tracked`** (lines 49–58):

Current (broken — Glimmer cannot observe `_patrons`):
```js
constructor() {
  super(...arguments);
  this._patrons = [];
  loadPatrons().then((users) => {
    this._patrons = users;
    if (api.container) {
      const appEvents = api.container.lookup("service:app-events");
      appEvents?.trigger("sidebar:refresh");
    }
  });
}
```
Replace with:
```js
@tracked patrons = [];

constructor() {
  super(...arguments);
  loadPatrons().then((users) => {
    this.patrons = users;
  });
}
```
Requires adding `tracked` import at the top of the file:
```js
import { tracked } from "@glimmer/tracking";
```

**Change 2 — Update `links` getter to use `patrons` instead of `_patrons`** (line 67):

Current:
```js
get links() {
  return this._patrons.slice(0, limit).map((u) => new PatronLink({ user: u }));
}
```
Replace with:
```js
get links() {
  return this.patrons.slice(0, limit).map((u) => new PatronLink({ user: u }));
}
```

**Existing import pattern** (lines 1–2) — reference for new `tracked` import placement:
```js
import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
// ADD:
import { tracked } from "@glimmer/tracking";
```

---

### `about.json` (config)

**Analog:** self — full file read above. One addition.

**Change — Add `theme_site_settings` block** after the closing brace of `color_schemes`:

Current structure ends at line 36 (`}`). Add before the final `}`:
```json
"theme_site_settings": {
  "enable_welcome_banner": false
}
```

Full resulting structure:
```json
{
  "name": "Liberty Tavern",
  "about_url": "...",
  "license_url": "...",
  "component": false,
  "color_schemes": { ... },
  "theme_site_settings": {
    "enable_welcome_banner": false
  }
}
```

---

### `common/common.scss` (stylesheet)

**Analog:** self — full file read above. Three targeted changes.

**Change 1 — Remove Google Fonts `@import`** (line 9):

Current:
```scss
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display...');
```
Delete this line entirely. Fonts are already loaded via `<link>` in `common/head_tag.html` (lines 1–3 of that file). Keeping both causes a double HTTP request.

**Change 2 — Replace hardcoded `--tavern-brass` with `accent_hue`-driven value** (lines 18–19 of `:root` block):

Current:
```scss
--tavern-brass: #c8941a;
```
Replace with (using SCSS variable interpolation for theme setting):
```scss
--tavern-brass: hsl(#{$accent_hue}, 68%, 45%);
```
`$accent_hue` is the SCSS variable name for the `accent_hue` theme setting (Discourse exposes `settings.yml` integer settings as SCSS variables via `$setting_name`). The fixed values `68%, 45%` come from `#c8941a` ≈ `hsl(37, 68%, 45%)`.

**Change 3 — Add BEM classes for removed inline styles** (append to `&__feature` block or after it, within `.tavern-banner { }` scope, lines 311–328):

Current `&__feature` block already exists (lines 312–328). Add two new BEM rules inside `.tavern-banner`:
```scss
&__feature-link {
  color: inherit;
  text-decoration: none;
}

&__feature-title {
  font-family: var(--font-display);
  font-style: italic;
  font-weight: 900;
  font-size: 24px;
  margin: 8px 0 4px;
}
```
These replace the inline `style="..."` attributes removed from `tavern-banner.hbs` lines 34–36.

---

## Shared Patterns

### Glimmer `@tracked` for Reactive Data
**Source:** `javascripts/discourse/components/tavern-banner.js` lines 12–15
**Apply to:** `honored-patrons.js` fix (replace `_patrons` with `@tracked patrons`)
```js
@tracked trending = [];
@tracked badges = [];
@tracked featured = null;
@tracked loading = true;
```
Pattern: declare as class field with `@tracked` decorator; simple assignment triggers re-render automatically.

### `apiInitializer("1.13.0", ...)` Shell
**Source:** `javascripts/discourse/api-initializers/honored-patrons.js` lines 1–5
**Apply to:** `theme-setup.js` (new file)
```js
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.13.0", (api) => {
  if (!settings.<guard_setting>) return;
  // api calls here
});
```
Version `"1.13.0"` is the minimum already in use — do not downgrade.

### BEM Class Naming
**Source:** `common/common.scss` lines 270+ (`.tavern-banner__*` blocks)
**Apply to:** any new SCSS classes added for removed inline styles
Pattern: `tavern-banner__<element>` for direct children, `tavern-banner__<element>--<modifier>` for variants. New classes `tavern-banner__feature-link` and `tavern-banner__feature-title` follow this convention.

### Settings Guard at Initializer Top
**Source:** `honored-patrons.js` line 5
**Apply to:** `theme-setup.js`
```js
if (!settings.honored_patrons_enabled) return;
```
Every api-initializer guards against its controlling setting at the top before any `api.*` calls.

---

## No Analog Found

All Phase 1 files have close analogs in the existing codebase. No new patterns are needed from external references.

---

## Metadata

**Analog search scope:** `javascripts/discourse/`, `common/`, root config files
**Files read:** 7 (tavern-banner.js, tavern-banner.hbs, honored-patrons.js, connector hbs, about.json, common.scss, settings.yml, head_tag.html)
**Pattern extraction date:** 2026-04-26
