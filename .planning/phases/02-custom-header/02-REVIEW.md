---
phase: 02-custom-header
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs
  - common/common.scss
  - javascripts/discourse/api-initializers/theme-setup.js
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-04-27
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files were reviewed: the `home-logo-contents` connector template, the global SCSS overrides, and the `theme-setup.js` api-initializer. The files are generally well-structured and follow Discourse's preferred patterns (no `common/header.html`, correct outlet usage, `@tracked` reactivity). One critical XSS issue exists in the banner template (triple-brace unescaped HTML) that is worth addressing even though the data source is internal. Four warnings cover a destructive i18n mutation, a banner-visibility SCSS rule that has a logic error, a missing loading-state guard in the template, and a `shouldShow` guard that misses the constructor timing. Two info items note minor code-quality concerns.

Note: `tavern-banner.js` and `tavern-banner.hbs` were read as cross-file context for the review of `theme-setup.js`. Findings sourced from those files are flagged as such.

---

## Critical Issues

### CR-01: Unescaped triple-brace renders `fancy_title` HTML without sanitization

**File:** `javascripts/discourse/components/tavern-banner.hbs:17, 36`
**Issue:** `{{{t.fancy_title}}}` and `{{{this.featured.fancy_title}}}` use Handlebars triple-brace syntax, which disables HTML escaping entirely. `fancy_title` is Discourse's HTML-formatted title (emoji, typographic replacements). It comes from the Discourse API, which does sanitize it server-side. However, any regression, staging misconfiguration, or future API change that permits unsanitized content would result in stored XSS in the banner that is visible to every homepage visitor. Discourse's own templates use the `html-safe` helper or `htmlSafe()` on explicitly trusted strings — not triple-braces on raw API values.

**Fix:** Use `{{t.title}}` (plain text) for link text and let the SCSS handle typographic presentation, or explicitly mark the value safe only after confirming it is already escaped:

```handlebars
{{! Option A — plain text (safe, loses emoji cooked HTML) }}
<a href={{this.topicUrl t}}>{{t.title}}</a>

{{! Option B — htmlSafe in the component (makes the trust contract explicit) }}
{{! In tavern-banner.js, add a getter: }}
{{! fancyTitle = (topic) => htmlSafe(topic.fancy_title ?? topic.title); }}
<a href={{this.topicUrl t}}>{{this.fancyTitle t}}</a>
```

---

## Warnings

### WR-01: i18n mutation is destructive — overwrites the shared translations object in place

**File:** `javascripts/discourse/api-initializers/theme-setup.js:16-43`
**Issue:** `translations.js.filters` and `translations.js.log_in` are mutated directly on the live `i18n.translations[locale]` object. This object is a singleton shared by all Discourse code. If any other theme, plugin, or Discourse core reads these keys after initialization but before the DOM renders, it gets the patched values — including admin interfaces and Discourse's own error messages that rely on `log_in`. If the api-initializer runs more than once (e.g., during hot-reload in development), the mutation applies to already-mutated strings. The guard `if (translations?.js)` prevents a null crash but does not prevent double-patching.

**Fix:** Use `i18n.t` override via the proper Discourse locale API instead of mutating the store, or at a minimum, skip the patch if it is already applied:

```js
// Idempotent guard
if (filters.latest && typeof filters.latest.title !== "object") {
  filters.latest.title = { zero: "Latest at the Bar", one: "Latest at the Bar (%{count})", other: "Latest at the Bar (%{count})" };
}
if (filters.top && filters.top.title !== "Top Shelf") {
  filters.top.title = "Top Shelf";
}
// etc.
```

A cleaner long-term fix is to add a `locales/en.yml` file to the theme. Theme locale files CAN override `js.filters.*` keys as of Discourse 3.x — the comment in the code saying they cannot is out of date for filter labels (it is only true for certain pluralized system keys).

### WR-02: Banner visibility SCSS selector has a logic error — hides banner on topic pages correctly but the `:not` chain is fragile and excludes categories

**File:** `common/common.scss:485-486`
**Issue:**
```scss
body:not(.navigation-topics):not(.navigation-categories):not(.archetype-regular) .tavern-banner,
body.archetype-regular .tavern-banner { display: none; }
```
Reading this literally: the first rule hides `.tavern-banner` when the body does NOT have `navigation-topics` AND NOT `navigation-categories` AND NOT `archetype-regular`. The second rule hides it when `archetype-regular` IS present (i.e., on topic pages). Together, the banner is hidden everywhere EXCEPT pages that have `navigation-topics` or `navigation-categories`. That is the intended behavior, but the selector also means that any page with an unexpected body class combination (e.g., a new Discourse route that does not add these classes) will accidentally show the banner. More importantly, `navigation-categories` causes the banner to show on the categories listing page — which may or may not be desired. The `shouldShow` JS guard in the component already limits rendering to `discovery.*` routes, so this CSS rule is a double-guard. If they get out of sync (e.g., a new discovery sub-route), the CSS hides a banner the JS correctly rendered.

**Fix:** Simplify to a single positive rule. Remove the CSS visibility guard entirely and rely solely on the JS `shouldShow` guard (which is more accurate and easier to maintain), or invert the logic to a simple show-only rule:

```scss
// Show only on homepage discovery routes; JS shouldShow guard handles the rest.
// This CSS fallback catches any case where JS renders but route doesn't match.
body:not(.navigation-topics):not(.navigation-categories) .tavern-banner {
  display: none;
}
```

Remove the `body.archetype-regular` rule — topic pages do not have `navigation-topics` or `navigation-categories`, so they are already caught by the `:not` chain.

### WR-03: `loadData()` is called in `constructor` but `shouldShow` depends on `router.currentRouteName` which may not be populated at construction time

**File:** `javascripts/discourse/components/tavern-banner.js:36-37`
**Issue:**
```js
constructor() {
  super(...arguments);
  if (this.shouldShow) this.loadData();
}
```
`shouldShow` reads `this.router.currentRouteName`. In Ember/Glimmer, the router service is injected but the current route name may be empty or `null` during the initial render pass before routing completes. If `currentRouteName` is `""` or `null`, the regex `/^discovery\./.test("")` returns `false`, so `loadData()` is never called and the banner renders in a permanent loading state. The component will show if `shouldShow` in the template returns `true` after routing settles (the getter re-evaluates reactively), but `loadData()` was already skipped.

**Fix:** Call `loadData()` unconditionally in the constructor (guarded only by the settings flag), and let `shouldShow` control template visibility. Data loading and route-based visibility are separate concerns:

```js
constructor() {
  super(...arguments);
  if (settings.show_homepage_banner) this.loadData();
}
```

Alternatively, trigger `loadData()` from a Glimmer modifier when the component actually mounts on a visible route.

### WR-04: `@outletArgs.title` in connector template may be undefined on some Discourse versions

**File:** `javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs:7`
**Issue:**
```handlebars
alt={{@outletArgs.title}}
```
The `home-logo-contents` outlet passes `outletArgs` from the header component. The `title` property comes from the site's `SiteSettings.title`. If the outlet args object is present but `title` is `undefined` (e.g., on a Discourse version that does not pass `title` in this outlet's args), the `alt` attribute renders as the string `"undefined"` in some Glimmer versions, or as an empty string. This is a minor accessibility issue — a missing or incorrect `alt` on the logo image.

**Fix:** Provide a fallback:

```handlebars
alt={{or @outletArgs.title "Liberty Tavern"}}
```

Or use the `site.title` service value in a backing JS class for this connector if one is added in the future.

---

## Info

### IN-01: `.btn-primary` overrides inside `.d-header` are duplicated at the global scope

**File:** `common/common.scss:60-71, 320-325`
**Issue:** Button styles for `.btn-primary` and `.sign-up-button` are defined twice — once nested inside `.d-header` (lines 60-71) and again at global scope (lines 320-325). The global `.btn-primary` rule sets `background: var(--tavern-oxblood)` while the `.d-header` nested rule sets `background: var(--tavern-brass)`. Since `.d-header .btn-primary` has higher specificity, header buttons get brass and global buttons get oxblood. This works, but the intent is not obvious and it means any change to global `.btn-primary` requires checking whether the header override also needs updating.

**Fix:** Add a comment at the global `.btn-primary` rule noting that header button overrides live in the `.d-header` block, so future maintainers know to look there.

### IN-02: `console.warn` left in production data-loading path

**File:** `javascripts/discourse/components/tavern-banner.js:92`
**Issue:**
```js
console.warn("Liberty Tavern banner: failed to load data", e);
```
This will appear in every visitor's browser console when the network request fails (e.g., during server maintenance, or if `/top.json` is rate-limited). It is not harmful, but it is noisy and may confuse forum members who open dev tools.

**Fix:** Either remove the `console.warn` or wrap it in a development-only guard:

```js
if (window.location.hostname === "localhost") {
  console.warn("Liberty Tavern banner: failed to load data", e);
}
```

---

_Reviewed: 2026-04-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
