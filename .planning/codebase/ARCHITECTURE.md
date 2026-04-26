# Architecture

**Analysis Date:** 2026-04-26

## Pattern Overview

**Overall:** Discourse Theme — CSS-override + Glimmer component extension

**Key Characteristics:**
- Non-destructive overlay: all styling targets Discourse's real DOM selectors via SCSS; no core files are replaced
- Live data via unauthenticated public REST endpoints (`/top.json`, `/badges.json`, `/groups/.../members.json`); no API key required
- Admin-controlled behavior through `settings.yml` theme settings; no hardcoded feature flags in application code
- Two independent JavaScript extension points: an `api-initializer` (sidebar) and a Glimmer component mounted via a plugin outlet (banner)

## Layers

**Theme Manifest:**
- Purpose: Declares theme identity, color schemes, and metadata
- Location: `about.json`
- Contains: Theme name, two color palettes (light + dark), license and about URLs
- Depends on: Nothing
- Used by: Discourse theme installer; Admin → Customize → Colors

**Settings Layer:**
- Purpose: Exposes all admin-editable configuration
- Location: `settings.yml`
- Contains: Typed settings (`bool`, `string`, `integer`, `enum`) with defaults and descriptions
- Depends on: Nothing
- Used by: All JavaScript files via the implicit `settings` global; referenced in templates as `this.settings`

**Static Asset Layer:**
- Purpose: Serves binary assets referenced by templates and documentation
- Location: `assets/`
- Contains: `logo.png` — the tavern logo used in the README preview
- Depends on: Nothing

**Presentation Layer (SCSS):**
- Purpose: Restyles all visual surfaces without rewriting Discourse's DOM structure
- Location: `common/common.scss`
- Contains: Eight named sections — Typography, Header, Sidebar, Search menu, Topic list, Categories, Buttons, Homepage banner
- Depends on: Discourse CSS custom properties (`--primary`, `--secondary`, `--tertiary`, etc.) and the color scheme declared in `about.json`
- Used by: Every page served by the Discourse instance

**Head Injection Layer:**
- Purpose: Loads Google Fonts before page paint
- Location: `common/head_tag.html`
- Contains: Three `<link>` preconnect/stylesheet tags for Playfair Display, Spectral, and Inter
- Depends on: External CDN (fonts.googleapis.com, fonts.gstatic.com)
- Used by: Browser; executes before body renders

**Plugin Outlet Mount:**
- Purpose: Injects the `<TavernBanner />` component into every page via Discourse's `below-site-header` outlet
- Location: `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`
- Contains: Single line: `<TavernBanner />`
- Depends on: `javascripts/discourse/components/tavern-banner.js` and `tavern-banner.hbs`
- Used by: Discourse outlet system; fires on every route

**Glimmer Component — TavernBanner:**
- Purpose: Renders the homepage welcome banner with live trending topics, featured topic card, and recent badges
- Location: `javascripts/discourse/components/tavern-banner.js`, `javascripts/discourse/components/tavern-banner.hbs`
- Contains: Route guard (`shouldShow`), async data loader (`loadData`), three `@tracked` state properties (`trending`, `badges`, `featured`), two helper methods (`categoryBadge`, `topicUrl`)
- Depends on: Discourse services (`router`, `site`), Discourse `ajax` helper, `categoryBadgeHTML` helper, Glimmer `@tracked`, theme `settings` global
- Used by: `connectors/below-site-header/tavern-banner.hbs`

**API Initializer — Honored Patrons:**
- Purpose: Registers a custom sidebar section showing real group members from a configurable Discourse group
- Location: `javascripts/discourse/api-initializers/honored-patrons.js`
- Contains: `PatronLink` class (extends `BaseCustomSidebarSectionLink`), anonymous section class (extends `BaseCustomSidebarSection`), one-shot fetch with promise cache
- Depends on: Discourse `apiInitializer`, `ajax`, `api.addSidebarSection`, `api.container` (for `service:app-events`), theme `settings` global, `I18n` global, `themePrefix` global
- Used by: Discourse's plugin API boot sequence

**Localization Layer:**
- Purpose: Provides all user-visible strings under a namespaced key
- Location: `locales/en.yml`
- Contains: Keys under `liberty_tavern.banner.*`, `liberty_tavern.sidebar.*`, `liberty_tavern.badges.*`; one `theme_metadata.description` key
- Depends on: Discourse I18n infrastructure
- Used by: `honored-patrons.js` via `I18n.t(themePrefix("liberty_tavern.sidebar.honored_patrons"))`; banner copy is currently hardcoded in the HBS template rather than pulled from I18n

## Data Flow

**Homepage Banner:**

1. Discourse renders the page; the `below-site-header` outlet fires and instantiates `<TavernBanner />`
2. `TavernBanner.constructor` checks `shouldShow`: guards on `settings.show_homepage_banner` and `router.currentRouteName` matching `/^discovery\./`
3. If shown, `loadData()` fires — fetches `/top.json?period=<setting>` first; falls back to `/latest.json` if fewer than 4 topics returned
4. Featured topic = `topics[0]`; trending strip = `topics[1..3]`
5. Separately fetches `/badges.json`; filters enabled badges with `grant_count > 0`, sorts by count descending, takes top 4
6. `@tracked` properties update; Glimmer re-renders the template sections gated by `this.settings.show_trending_strip` and `this.showBadges`

**Honored Patrons Sidebar:**

1. `apiInitializer` runs at boot; exits early if `settings.honored_patrons_enabled` is false
2. `loadPatrons()` fires once per page load, fetching `/groups/<groupName>/members.json?limit=<count>&order=added_at&asc=false`; result is promise-cached
3. Section class constructor calls `loadPatrons().then(...)` and triggers `sidebar:refresh` via `service:app-events` when data arrives
4. `links` getter maps each user object to a `PatronLink` instance exposing avatar, username, name, and trust-level suffix

**State Management:**
- Component state uses Glimmer `@tracked` properties (no external store)
- Sidebar patron list is cached in a module-scoped `patronsPromise` variable — reset only on full page reload
- No shared state between the banner component and the sidebar initializer

## Key Abstractions

**`settings` global:**
- Purpose: Provides all admin-configured values to JavaScript at runtime
- Examples: `settings.show_homepage_banner`, `settings.honored_patrons_group`, `settings.trending_period`
- Pattern: Implicit global injected by Discourse's theme system; accessed directly (no import needed)

**`themePrefix()` global:**
- Purpose: Namespaces I18n keys to avoid collisions with core and other themes
- Examples: `themePrefix("liberty_tavern.sidebar.honored_patrons")`
- Pattern: Implicit global; wraps key strings before passing to `I18n.t()`

**`BaseCustomSidebarSection` / `BaseCustomSidebarSectionLink`:**
- Purpose: Discourse-provided base classes for registering custom sidebar sections
- Examples: `javascripts/discourse/api-initializers/honored-patrons.js`
- Pattern: Subclassed with getter overrides; registered via `api.addSidebarSection(factory)`

**Plugin Outlet connector:**
- Purpose: Mounts arbitrary Glimmer components at named extension points in Discourse's template tree
- Examples: `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`
- Pattern: File path encodes the outlet name; template content is the component invocation

## Entry Points

**`about.json`:**
- Location: `about.json`
- Triggers: Theme installation and color scheme selection
- Responsibilities: Declares the theme as a full theme (not a component), registers two color palettes

**`common/head_tag.html`:**
- Location: `common/head_tag.html`
- Triggers: Every page load, injected into `<head>`
- Responsibilities: Loads Google Fonts before FOUT can occur

**`common/common.scss`:**
- Location: `common/common.scss`
- Triggers: Compiled and served on every page
- Responsibilities: All visual overrides across header, sidebar, search, topic list, categories, buttons, and banner

**`javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`:**
- Location: `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`
- Triggers: Every page render via Discourse's outlet system
- Responsibilities: Mounts `<TavernBanner />`; the component self-suppresses on non-discovery routes

**`javascripts/discourse/api-initializers/honored-patrons.js`:**
- Location: `javascripts/discourse/api-initializers/honored-patrons.js`
- Triggers: Discourse plugin API boot, once per page load
- Responsibilities: Registers the Honored Patrons sidebar section if the setting is enabled

## Error Handling

**Strategy:** Silent degradation — all fetch failures are caught and result in empty state; the UI renders with whatever data is available

**Patterns:**
- `ajax(...).catch(() => null)` in `TavernBanner.loadData()` — failed fetches return null; null-safe optional chaining extracts topic arrays
- `ajax(...).catch(() => [])` in `honored-patrons.js` — failed patron fetch returns empty array; sidebar section renders with zero links
- `console.warn(...)` in the banner's outer try/catch — failure is logged but never surfaced to the user
- CSS route guard via `body:not(.navigation-topics)...` in `common.scss` hides the banner on non-homepage routes as a layout safety net independent of the JavaScript guard

## Cross-Cutting Concerns

**Fonts:** Loaded via `common/head_tag.html` (Google Fonts CDN); CSS variables `--font-display`, `--font-serif`, `--font-ui` defined in `:root` in `common.scss` and referenced throughout all SCSS sections

**Theme settings access:** All JavaScript files access the implicit `settings` global directly — no wrapper, no import

**Route awareness:** `TavernBanner` uses the injected `@service router` to check `currentRouteName`; the CSS also applies a `display: none` rule based on `body` class names as a fallback

**I18n:** All translatable strings are namespaced under `liberty_tavern.*` in `locales/en.yml` and accessed via `themePrefix()` + `I18n.t()`; banner template copy is currently hardcoded in the HBS rather than sourced from I18n keys

---

*Architecture analysis: 2026-04-26*
