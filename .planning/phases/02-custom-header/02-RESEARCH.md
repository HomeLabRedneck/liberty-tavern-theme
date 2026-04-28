# Phase 2: Custom Header — Research

**Researched:** 2026-04-27
**Domain:** Discourse 3.x theme — header customization via plugin outlets, SCSS, and i18n
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Logo area via `connectors/home-logo-contents/tavern-logo.hbs` only. No Glimmer JS file. Markup: `<img>` using `{{theme-asset 'logo.png'}}` + `.tavern-logo__title` span + `.tavern-logo__tagline` span.
- **D-02:** Nav links via I18n rename + `top_menu` site setting. Rename Discourse's native nav pills in `locales/en.yml`: `latest` → "Latest at the Bar", `top` → "Top Shelf", `categories` → "Rooms". Add `/hot` to the `top_menu` for "Trending". Native active-state styling works automatically.
- **D-03:** Nav link routes — Trending → `/hot`, Rooms → `/categories`, Latest at the Bar → `/latest`, Top Shelf → `/top`.
- **D-04:** Style existing `.d-header .login-button` via SCSS only. Zero new JS. Button already renders for anonymous users.

### Claude's Discretion
- I18n key paths for nav renames: Claude selects correct `js.filters.*` key names.
- `top_menu` site setting modification: Claude determines whether `theme_site_settings` or admin-only.
- BEM class names for connector HBS elements: use `.tavern-logo__*` pattern.

### Deferred Ideas (OUT OF SCOPE)
None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HEAD-01 | Custom header displays the Liberty Tavern logo on every page | `home-logo-contents` outlet verified in Discourse source; connector HBS-only confirmed |
| HEAD-02 | Header displays site title "The Liberty Tavern" and tagline "Free Speech · Est. MDCCXCI" | Logo connector markup pattern confirmed; `@outletArgs.title` available |
| HEAD-03 | Header displays navigation links: Trending, Rooms, Latest at the Bar, Top Shelf | `top_menu` is admin-only (not themeable); I18n override approach requires JS workaround; admin doc required |
| HEAD-04 | Header displays Sign In button for anonymous users | `.d-header .login-button` confirmed in auth-buttons.gjs; SCSS-only approach confirmed |
| HEAD-05 | Discourse's native search and user-menu buttons remain functional | SCSS-only approach to header preserves all native buttons |
</phase_requirements>

---

## Summary

Phase 2 delivers three distinct deliverables: (1) a logo connector replacing the default Discourse logo area, (2) nav link customization, and (3) a styled Sign In button. Each has a different implementation path and different risk level.

**Logo connector** (`home-logo-contents`): the outlet is confirmed in current Discourse source (`frontend/discourse/app/components/header/home-logo.gjs`). It is a classic wrapper outlet — when a connector is present, it replaces the default `<HomeLogoContents>` rendering. The outlet passes `logoSmallUrl`, `logoUrl`, `minimized`, `showMobileLogo`, `mobileLogoUrl`, and `title` via `@outletArgs`. HBS-only connectors are confirmed to work without a companion `.js` file. Access outlet args via `{{@outletArgs.title}}` syntax (works in both classic and Glimmer outlets per developer docs).

**Nav link labels** (CRITICAL FINDING — D-02 assumption is incorrect): Theme `locales/en.yml` files operate in a **theme-specific namespace** (`theme_translation.{theme_id}.*`). They CANNOT override core Discourse strings like `js.filters.latest.title`. This is confirmed by multiple official Discourse Meta sources. The nav pill display names are generated from `i18n('filters.{name}.title')` in `nav-item.js` (verified in Discourse source). Overriding these requires either (a) the admin's `/admin/customize/site_texts` UI, or (b) JavaScript in an api-initializer that patches `I18n.translations` directly. The `top_menu` setting does NOT have `themeable: true` in `config/site_settings.yml` — it cannot be set via `theme_site_settings` in `about.json`.

**Sign In button**: The `auth-buttons.gjs` component renders `.login-button` for anonymous users using `@label="log_in"` (maps to `js.log_in = "Log In"`). The button already exists in `.d-header` — SCSS targeting `.d-header .login-button` is confirmed as the correct approach. The button label "Log In" → "Sign In" rename requires the admin site text interface (same constraint as nav labels).

**Primary recommendation:** Proceed with logo connector (straightforward), SCSS styling (straightforward), and document the admin one-time steps for nav label renames and `top_menu` order as part of the plan deliverables. Use JS api-initializer to patch `I18n.translations` for nav pill renames if inline automation is preferred over admin docs.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Logo rendering | Frontend (Glimmer outlet connector) | — | Replaces content inside existing header component via plugin outlet |
| Nav pill labels | Browser i18n layer | API-initializer JS | Core `filters.*.title` keys belong to Discourse's i18n bundle; overrides happen in JS runtime |
| `top_menu` item order/set | Admin site setting (server-side) | — | Not themeable; requires manual admin change or JS nav item registration |
| Sign In button styling | SCSS (`.d-header .login-button`) | — | Button already rendered by `auth-buttons.gjs`; styling is pure SCSS |
| Button label rename | Admin site text (`/admin/customize/site_texts`) | JS `I18n.translations` patch | Core string `js.log_in`; not overridable via theme locale YAML |

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| Discourse Plugin Outlet (HBS connector) | 3.2+ | Replace logo area content | Supported pattern; survives Discourse upgrades; no template overrides needed |
| Discourse SCSS (common.scss) | 3.2+ | Style login-button, logo area | Already in use in this theme; only correct way to style `.d-header` elements |
| Discourse api-initializer | 1.13.0 | JS hook for i18n patches if needed | Already used in `theme-setup.js`; standard entry point for theme JS |

### Supporting
| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| `I18n.translations` JS patch | runtime | Override nav pill labels and Sign In text | If avoiding admin step is required; fragile across locales |
| `/admin/customize/site_texts` | admin UI | Override `js.filters.latest.title` etc. | Preferred; permanent, locale-aware |
| `/admin/config/navigation` | admin UI | Reorder `top_menu` items | Preferred; permanent |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| HBS-only connector | `.gjs` Glimmer component | GJS needed only if JS logic required; HBS-only is simpler and sufficient |
| Admin site text overrides | JS `I18n.translations` patch | JS patch is fragile; only works for `en` locale unless patching all locales |
| `top_menu` admin change | `api.addNavigationBarItem` | addNavItem ADDS new items; can't rename/reorder existing `latest/top/categories` |

---

## Architecture Patterns

### System Architecture Diagram

```
Browser request (any page)
        |
        v
Discourse renders .d-header
        |
        |---> HomeLogo component
        |         |
        |         +---> PluginOutlet "home-logo"
        |                   |
        |                   +---> PluginOutlet "home-logo-contents"  <── connector fires here
        |                             |
        |                             +---> [connector present] tavern-logo.hbs
        |                                       renders: img + .tavern-logo__title + .tavern-logo__tagline
        |
        |---> NavigationBar component
        |         |
        |         +---> NavItem.buildList() reads siteSettings.top_menu
        |         +---> each NavItem.displayName = i18n("filters.{name}.title")
        |         +---> [admin override] site_texts override → custom display name
        |
        |---> AuthButtons component (anonymous users only)
                  |
                  +---> .login-button rendered with label "log_in"
                  +---> [SCSS] .d-header .login-button { brass styles }
```

### Recommended Project Structure

```
javascripts/discourse/
├── api-initializers/
│   └── theme-setup.js          # existing; may add i18n patches here
├── connectors/
│   └── home-logo-contents/
│       └── tavern-logo.hbs     # NEW — logo connector
locales/
│   └── en.yml                  # existing; theme-namespace keys only
common/
│   └── common.scss             # existing; extend .d-header block
```

### Pattern 1: HBS-only Plugin Outlet Connector

**What:** Replaces default content inside a wrapper outlet with no JavaScript needed.
**When to use:** When the replacement is pure markup with no computed logic.

```handlebars
{{! connectors/home-logo-contents/tavern-logo.hbs }}
{{! Source: discourse-developer-docs/13-plugin-outlet-connectors.md }}
<img
  class="tavern-logo__img"
  src={{theme-asset "logo.png"}}
  alt={{@outletArgs.title}}
/>
<span class="tavern-logo__title">The Liberty Tavern</span>
<span class="tavern-logo__tagline">Free Speech · Est. MDCCXCI</span>
```

**Key facts:**
- Access outlet args via `{{@outletArgs.argName}}` — works in both classic and Glimmer outlets.
- `@outletArgs.title` = value of `siteSettings.title` (passed by `HomeLogo` component).
- The connector fires inside `<a href="/">` so the whole logo area is already a home link.
- No wrapper `<div>` needed — connector renders directly inside the `<a>`.

### Pattern 2: SCSS Extension for .d-header

**What:** Extend the existing `.d-header` block in `common.scss` with login-button and logo styles.
**When to use:** Any header visual change.

```scss
// Source: CLAUDE.md + existing common.scss patterns
// Add to the existing .d-header {} block (lines 40-72 of common.scss)
.d-header {
  // ... existing styles ...

  .login-button {
    background: var(--tavern-brass);
    color: #1a120c;
    font-family: var(--font-ui);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    font-size: 11px;
    border-radius: 2px;
    border: none;
    &:hover { filter: brightness(1.15); }
  }
}

.tavern-logo__img {
  height: 40px;
  width: auto;
  display: block;
}
.tavern-logo__title {
  font-family: var(--font-display);
  font-style: italic;
  font-weight: 900;
  color: var(--tavern-cream);
  font-size: 18px;
  line-height: 1;
  letter-spacing: -0.01em;
}
.tavern-logo__tagline {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--tavern-brass);
  opacity: 0.85;
}
```

### Pattern 3: JS api-initializer i18n Patch (if needed for nav labels)

**What:** Directly mutates Discourse's `i18n` translation store at runtime.
**When to use:** When admin site-text step is not acceptable.

```javascript
// Source: meta.discourse.org/t/can-you-override-the-locale-via-theme-files/263355
// Place in theme-setup.js inside the apiInitializer callback
import { i18n } from "discourse-i18n";

// After apiInitializer fires, patch translations for the English locale
const locale = i18n.currentLocale();
if (i18n.translations[locale]) {
  const filters = i18n.translations[locale].js?.filters;
  if (filters) {
    if (filters.latest) filters.latest.title = { zero: "Latest at the Bar", one: "Latest at the Bar", other: "Latest at the Bar" };
    if (filters.top) filters.top.title = "Top Shelf";
    if (filters.categories) filters.categories.title = "Rooms";
  }
}
```

**WARNING:** `filters.latest.title` is a pluralized key (zero/one/other variants) per the Discourse Meta bug report. Overriding only the string rather than the object may fail. Verify with live testing.

**WARNING:** This pattern does not work for non-English locales unless all locale entries are patched.

### Anti-Patterns to Avoid

- **`common/header.html`:** Injecting raw HTML into the header — tried and reverted 3 times per project history. Not needed; use outlet.
- **`display: flex` or `flex-direction` on `.d-header`:** CLAUDE.md prohibition — Glimmer-header migration in 3.4+ changes classes; only use colors/fonts/borders/height.
- **Theme `locales/en.yml` for core strings:** Theme locale files use a theme-specific namespace and CANNOT override `js.filters.*` or `js.log_in`. This is a confirmed Discourse limitation.
- **`theme_site_settings: { top_menu: "..." }` in about.json:** `top_menu` does NOT have `themeable: true` — this entry would be silently ignored.
- **`api.addNavigationBarItem` to rename existing items:** This API adds NEW nav items; it cannot rename or replace existing `latest`, `top`, `categories` entries.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Logo replacement | Custom header template | `home-logo-contents` outlet connector | Outlet is the Discourse-blessed override point; template overrides deprecated |
| Nav label rename | Custom nav component | Admin site texts + optional JS patch | Core i18n system handles pluralization, locale fallback, and caching |
| Sign In button | New button element | SCSS on existing `.login-button` | Button already rendered by `auth-buttons.gjs` — duplicate button causes double-modal bug |
| Top menu ordering | JS rewrite of nav building | Admin site setting change | `top_menu` is server-side; nav items built from this setting server-side at serialization |

**Key insight:** The header is 90% complete out of the box. Phase 2 is cosmetic overlay (SCSS + logo connector), not structural replacement.

---

## Common Pitfalls

### Pitfall 1: Theme locales/en.yml cannot override core strings

**What goes wrong:** Developer adds `js: > filters: > latest: > title: "Latest at the Bar"` to theme `locales/en.yml` and wonders why nothing changes.
**Why it happens:** Theme locale files are namespaced under `theme_translation.{theme_id}.*`. They do not merge into the global `js.*` namespace. Only custom theme keys (accessed via `{{theme-i18n "my.key"}}`) come from theme locale files.
**How to avoid:** Use admin `/admin/customize/site_texts` or JS `I18n.translations` patch in an api-initializer.
**Warning signs:** Nav pills show original labels despite en.yml entries for `js.filters.*`.

### Pitfall 2: `top_menu` is not a themeable site setting

**What goes wrong:** Developer adds `"theme_site_settings": { "top_menu": "hot|latest|categories|top" }` to `about.json` expecting to add the `hot` filter.
**Why it happens:** Only settings with `themeable: true` in Discourse's `config/site_settings.yml` are accepted in `theme_site_settings`. `top_menu` lacks this flag.
**How to avoid:** Change `top_menu` via Admin → Settings → Basic Setup (or the Navigation admin page). Document this as a one-time admin setup step in the phase plan.
**Warning signs:** `hot` pill never appears even after `about.json` change; no error is shown.

### Pitfall 3: home-logo-contents outlet args access syntax

**What goes wrong:** Connector HBS uses `{{logoUrl}}` or `{{this.logoUrl}}` instead of `{{@outletArgs.logoUrl}}` and gets undefined.
**Why it happens:** Classic outlet connectors historically surfaced args directly as template properties, but this behavior varies by Discourse version and outlet configuration.
**How to avoid:** Always use `{{@outletArgs.argName}}` — documented as the forward-compatible syntax that works in both classic and Glimmer outlets.
**Warning signs:** Logo appears blank or default Discourse logo shows instead of connector content.

### Pitfall 4: filters.latest.title is a pluralized key

**What goes wrong:** JS patch assigns a plain string to `i18n.translations.en.js.filters.latest.title` and the pill shows `[missing "en.filters.latest.title" translation]`.
**Why it happens:** The `latest` filter title is a pluralized key with `{ zero, one, other }` variants (confirmed in Discourse Meta bug report). Assigning a plain string breaks the pluralization lookup.
**How to avoid:** Assign a pluralized object: `{ zero: "Latest at the Bar", one: "Latest at the Bar (%{count})", other: "Latest at the Bar (%{count})" }`. Or use admin site texts which handles this automatically.
**Warning signs:** Missing translation errors in browser console after JS patch.

### Pitfall 5: Login button appears for logged-in users (false positive)

**What goes wrong:** SCSS for `.login-button` also affects `.d-header .login-button` shown in some admin UI contexts, creating visual artifact.
**Why it happens:** `auth-buttons.gjs` conditionally renders the button based on `showLoginButton` guard, but `.d-header` SCSS is always applied.
**How to avoid:** Scope `.login-button` styles within `.d-header` as already done with `.sign-up-button` in the existing SCSS. The button's CSS presence/absence is handled by Discourse's conditional rendering.
**Warning signs:** Not a real risk — `.login-button` is only rendered for anonymous users per `auth-buttons.gjs` logic.

---

## Code Examples

### Verified: home-logo-contents outlet args (from Discourse source)

```javascript
// Source: frontend/discourse/app/components/header/home-logo.gjs (verified 2026-04-27)
// Available @outletArgs passed to home-logo-contents:
// logoSmallUrl, logoSmallUrlDark, logoUrl, logoUrlDark,
// minimized, mobileLogoUrl, mobileLogoUrlDark, showMobileLogo, title
```

### Verified: auth-buttons.gjs login button (from Discourse source)

```javascript
// Source: frontend/discourse/app/components/header/auth-buttons.gjs (verified 2026-04-27)
// The login button:
<DButton
  class="btn-primary btn-small login-button"
  @action={{@showLogin}}
  @label="log_in"          // → js.log_in = "Log In"
  @icon="user"
/>
// Rendered only when: !this.header.headerButtonsHidden.includes("login")
// and this.args.canSignUp check doesn't gate it
```

### Verified: nav-item.js displayName key (from Discourse source)

```javascript
// Source: frontend/discourse/app/models/nav-item.js (verified 2026-04-27)
// Nav pill display name lookup:
const titleKey = count === 0 ? ".title" : ".title_with_count";
return emojiUnescape(
  i18n(`filters.${this.name.replace("/", ".") + titleKey}`, extra)
);
// So: filters.latest.title, filters.top.title, filters.hot.title, filters.categories.title
```

### Verified: HBS connector access pattern (from developer docs)

```handlebars
{{! Source: discourse-developer-docs/13-plugin-outlet-connectors.md }}
{{! Use @outletArgs.* — works in both classic and Glimmer outlets }}
<img src={{theme-asset "logo.png"}} alt={{@outletArgs.title}} />
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `common/header.html` HTML injection | Plugin outlets + SCSS | Pre-3.0 deprecation cycle | Template overrides fully removed in late 2024 |
| `connectors/below-site-header/` | `connectors/discovery-list-container-top/` or api.renderInOutlet | Phase 1 of this project | Below-site-header renders outside #main-outlet-wrapper |
| Classic Ember components in connectors | Template-only Glimmer components | Discourse 3.3+ | GJS format available; HBS still valid for simple connectors |
| `{{model}}` / `{{this.model}}` outlet args | `{{@outletArgs.model}}` | Ongoing migration | Old syntax still works in classic outlets but is not forward-compatible |
| `I18n.translations.en.js.filters.latest.title = "string"` | Pluralized object `{ zero, one, other }` | N/A | `latest.title` was always pluralized; plain string assignment breaks lookup |

**Deprecated/outdated:**
- Template overrides (`common/header.html`): fully removed Discourse late 2024. Do not use.
- Direct `{{argName}}` in connectors: still works in classic outlets but not recommended; use `@outletArgs.argName`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `hot` filter is available in Discourse 3.2 (included in `top_menu` choices per site_settings.yml) | Standard Stack | If `hot` not available on this instance's version, "Trending" nav pill won't render |
| A2 | `.login-button` SCSS class name unchanged in Discourse 3.2+ | SCSS patterns | If auth-buttons class changed, styles won't apply; verify in DevTools |
| A3 | Site-text admin overrides persist across theme updates | Nav label approach | If overrides reset on theme update, nav labels revert — unlikely but unverified |
| A4 | `i18n.translations.en.js.filters.latest.title` is an object with `{ zero, one, other }` keys in Discourse 3.2 on this instance | JS patch pattern | If structure differs, patch won't work as expected |

**If this table is empty for a given item:** All other claims were verified against Discourse source code or official documentation in this session.

---

## Open Questions

1. **Is the `hot` filter currently enabled on the live instance's `top_menu`?**
   - What we know: `hot` is a valid `top_menu` choice per `config/site_settings.yml`. The default value is `"latest|new|unread|hot|categories"` which includes `hot`.
   - What's unclear: Whether the live instance's admin has modified `top_menu` to remove `hot`.
   - Recommendation: Document as admin verification step. If `hot` is missing, admin adds it via Admin → Settings → Basic Setup → top menu.

2. **Preferred approach for nav label renames — admin UI vs JS patch?**
   - What we know: Admin site texts are permanent and locale-aware. JS patch is fragile and English-only.
   - What's unclear: Whether the forum owner wants zero admin steps or is OK with one-time admin setup.
   - Recommendation: Plan for **admin site text step** as the primary approach (correct, permanent, supported). Include JS patch as an optional fallback in a note. The context (D-02) says "via I18n overrides in `locales/en.yml`" — this approach must be corrected to the admin UI method.

3. **`home-logo-contents` outlet: does the connector REPLACE or APPEND?**
   - What we know: It is a wrapper outlet — the default `<HomeLogoContents>` is the fallback. When a connector is present, Discourse renders the connector instead.
   - What's unclear: Whether "instead" is accurate or whether both connector AND default render.
   - Recommendation: VERIFIED from source — `<PluginOutlet @name="home-logo-contents">` wraps `<HomeLogoContents>` as the default content. Connector replaces it. Safe to proceed.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 2 is code/config changes only. No external CLI tools, databases, or services required beyond the existing Discourse instance (already verified running in Phase 1).

---

## Validation Architecture

> `workflow.nyquist_validation` key absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual visual verification (no automated test framework for Discourse themes) |
| Config file | none |
| Quick run command | Visual check in browser after theme upload |
| Full suite command | Per-phase UAT checklist |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HEAD-01 | Logo image renders on every page | manual | Load `/`, `/latest`, `/categories`, any topic | n/a |
| HEAD-02 | Title and tagline appear next to logo | manual | Inspect `.tavern-logo__title` and `.tavern-logo__tagline` text | n/a |
| HEAD-03 | Nav pills show: Trending, Rooms, Latest at the Bar, Top Shelf | manual | Check nav-pills text after admin site text overrides | n/a |
| HEAD-04 | Sign In button shows for anonymous users with brass styling | manual | Open incognito browser; check `.login-button` styling | n/a |
| HEAD-05 | Search icon opens search; user avatar opens user menu | manual | Click search icon, click user menu; confirm no regression | n/a |

### Wave 0 Gaps
None — no test infrastructure needed; Discourse themes use manual UAT by design.

---

## Security Domain

> `security_enforcement` absent from config — treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase adds no auth logic; login button is Discourse native |
| V3 Session Management | No | No session management changes |
| V4 Access Control | No | Logo/nav visible to all; no access control changes |
| V5 Input Validation | No | No user input processed |
| V6 Cryptography | No | No cryptographic operations |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via unsanitized theme asset URL | Tampering | `theme-asset` helper is Discourse-controlled and outputs a CDN URL; not a user input |
| CSS injection via SCSS | Tampering | SCSS is theme code, not user-controlled; no user-facing SCSS interpolation |

**No security concerns introduced by Phase 2.** The connector is pure static markup, the SCSS contains no user input interpolation, and the login button is Discourse native.

---

## Sources

### Primary (HIGH confidence)
- `frontend/discourse/app/components/header/home-logo.gjs` — verified outlet structure, outletArgs, wrapper behavior [VERIFIED: GitHub API direct fetch 2026-04-27]
- `frontend/discourse/app/components/header/home-logo-contents.gjs` — confirmed component content, no PluginOutlet inside it [VERIFIED: GitHub API direct fetch 2026-04-27]
- `frontend/discourse/app/components/header/auth-buttons.gjs` — confirmed `.login-button` class and `log_in` label key [VERIFIED: GitHub API direct fetch 2026-04-27]
- `frontend/discourse/app/models/nav-item.js` — confirmed `filters.{name}.title` key pattern for displayName [VERIFIED: GitHub API direct fetch 2026-04-27]
- `frontend/discourse/app/lib/plugin-api.gjs` — confirmed `addNavigationBarItem` API signature [VERIFIED: GitHub API direct fetch 2026-04-27]
- `config/site_settings.yml` — confirmed `top_menu` has no `themeable: true` [VERIFIED: WebFetch from github.com 2026-04-27]
- `discourse-developer-docs/13-plugin-outlet-connectors.md` — confirmed `@outletArgs` access pattern, HBS-only connectors [CITED: github.com/discourse/discourse-developer-docs]

### Secondary (MEDIUM confidence)
- meta.discourse.org/t/add-localizable-strings-to-themes-and-theme-components/109867 — confirmed theme locale namespace isolation [CITED: official Discourse Meta developer guide]
- meta.discourse.org/t/can-you-override-the-locale-via-theme-files/263355 — confirmed YAML locale files cannot override core js.* strings [CITED: Discourse Meta developer discussion]
- meta.discourse.org/t/controlling-site-settings-with-themes/374376 — confirmed `themeable: true` mechanism; `top_menu` not in thermeable set [CITED: official Discourse Meta developer guide]
- meta.discourse.org/t/js-filters-latest-title-incomplete-pluralization-in-transifex/34116 — confirmed `filters.latest.title` is pluralized (zero/one/other) [CITED: Discourse Meta bug report]

### Tertiary (LOW confidence)
- meta.discourse.org/t/can-you-customize-override-core-text-with-a-theme-component/283974 — confirmed theme components cannot override core text via locale files (single community thread) [LOW — single source, no official doc]

---

## Metadata

**Confidence breakdown:**
- Logo connector (`home-logo-contents` outlet): HIGH — verified directly in Discourse source
- SCSS approach for login-button: HIGH — verified in auth-buttons.gjs source
- Nav label override limitation: HIGH — confirmed via multiple Discourse Meta official sources
- `top_menu` not themeable: HIGH — verified in config/site_settings.yml
- JS `I18n.translations` patch syntax: MEDIUM — confirmed community approach; pluralization behavior is LOW until live-tested

**Research date:** 2026-04-27
**Valid until:** 2026-07-27 (90 days; Discourse is relatively stable in this area)
