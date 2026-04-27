# Phase 2: Custom Header — Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace Discourse's default header chrome with the Liberty Tavern header bar on every page: logo image + title + tagline in the logo area, 4 nav links (Trending, Rooms, Latest at the Bar, Top Shelf), and a styled Sign In button for anonymous users — while keeping native search icon and user-menu fully functional.

</domain>

<decisions>
## Implementation Decisions

### Logo Area
- **D-01:** Render logo via simple connector HBS at `connectors/home-logo-contents/tavern-logo.hbs`. No Glimmer JS file. Markup: `<img>` using `{{theme-asset 'logo.png'}}` + `.tavern-logo__title` span + `.tavern-logo__tagline` span. No JS logic required.

### Nav Links
- **D-02:** Render nav links via I18n rename + `top_menu` site setting. Rename Discourse's native nav pills in `locales/en.yml`: `latest` → "Latest at the Bar", `top` → "Top Shelf", `categories` → "Rooms". Add `/hot` to the `top_menu` site setting for "Trending". Native Discourse active-state styling works automatically.
- **D-03:** Nav link routes — Trending → `/hot`, Rooms → `/categories`, Latest at the Bar → `/latest`, Top Shelf → `/top`.

### Sign In Button
- **D-04:** Style the existing Discourse `.d-header .login-button` via SCSS only. Zero new JS. The button already renders for anonymous users — apply tavern styling (brass color, uppercase, etc.) matching Image 1. Discourse's default login modal opens on click (no custom action needed).

### Claude's Discretion
- I18n key paths for nav renames: Claude selects the correct `js.filters.*` or `js.nav.*` key names based on Discourse's actual translation file structure.
- `top_menu` site setting modification: Claude determines whether to set this via `theme_site_settings` in `about.json` or document it as a required admin setting change.
- BEM class names for connector HBS elements: Claude follows `.tavern-logo__*` pattern consistent with Phase 1.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Research & Requirements
- `.planning/research/SUMMARY.md` — Phase 2 section (§3 Phase Ordering: Custom Header) with outlet strategy and pitfall #3 (do not target `.d-header` for layout properties)
- `.planning/REQUIREMENTS.md` — HEAD-01..05 requirements with acceptance criteria
- `.planning/ROADMAP.md` — Phase 2 goal and 4 success criteria

### Prior Phase Decisions
- `.planning/phases/01-foundation-repair/01-CONTEXT.md` — D-03: `theme-setup.js` is the home for API calls; grows as Phase 2 adds header setup

### Existing Code (files being modified or created)
- `javascripts/discourse/api-initializers/theme-setup.js` — may gain header API calls in this phase
- `common/common.scss` — `.d-header` section (lines 39–72) already styles header background, borders, fonts, and `.sign-up-button`; Phase 2 adds `.login-button` styling and any logo-area CSS
- `assets/logo.png` — existing logo image, referenced via `{{theme-asset 'logo.png'}}`
- `locales/en.yml` — new file; override Discourse nav labels via I18n keys
- `connectors/home-logo-contents/tavern-logo.hbs` — new connector file; replaces default logo area

### Critical Rules (from CLAUDE.md)
- No `common/header.html` — HTML injection in header was tried and reverted 3 times. Use `home-logo-contents` outlet + `api.headerIcons.add()` + SCSS.
- Do NOT target `.d-header` for layout properties (flex-direction, display, position) — only colors, fonts, borders, height. Risk: Glimmer-header migration in Discourse 3.4+ changes classes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `assets/logo.png` — logo image already present; reference via `{{theme-asset 'logo.png'}}` in HBS
- `theme-setup.js` — api-initializer already wired; add `api.headerIcons.add()` calls here if needed
- `common/common.scss` `.d-header` block — already styled (dark background, brass border, cream text, `.sign-up-button` brass styling); Phase 2 extends this block

### Established Patterns
- BEM class naming: `.tavern-banner__*` established in Phase 1 → use `.tavern-logo__*` for logo area
- `apiInitializer("1.13.0", (api) => {...})` — already in use in `theme-setup.js` and `honored-patrons.js`
- Connector files: `connectors/{outlet-name}/{name}.hbs` pattern (previously `connectors/below-site-header/` — deleted)

### Integration Points
- `home-logo-contents` outlet replaces `.d-header .title` logo area; connector drops in without modifying existing files
- `locales/en.yml` is a new file; Discourse loads theme locale overrides automatically
- `top_menu` site setting may need admin change or `theme_site_settings` entry — verify if overridable via theme

</code_context>

<specifics>
## Specific Ideas

- The connector HBS layout should be horizontal: logo image left-aligned, title + tagline stacked to the right. Matches standard header logo conventions.
- Sign In button: rename label "Log In" → "Sign In" via `locales/en.yml` if the key exists; then style `.d-header .login-button` to match the brass button design. Do not add a second button.
- `top_menu` note: Discourse site setting `top_menu` controls which nav items appear and in what order. If not overridable via theme, document it as a required one-time admin setting: `hot|latest|categories|top`.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-custom-header*
*Context gathered: 2026-04-26*
