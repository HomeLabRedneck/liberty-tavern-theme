# Codebase Structure

**Analysis Date:** 2026-04-26

## Directory Layout

```
discourse-theme/
├── about.json                              # Theme manifest + 2 color schemes
├── settings.yml                            # Admin-editable theme settings (9 settings)
├── README.md                               # Installation and feature docs
├── assets/
│   └── logo.png                            # Tavern logo (used in README preview)
├── common/
│   ├── common.scss                         # All SCSS overrides (394 lines, 8 sections)
│   ├── head_tag.html                       # Google Fonts <link> tags
│   └── after_header.html                   # Empty; comment explains connector approach
├── locales/
│   └── en.yml                              # I18n strings under liberty_tavern.*
└── javascripts/discourse/
    ├── api-initializers/
    │   └── honored-patrons.js              # Sidebar section via api.addSidebarSection
    ├── components/
    │   ├── tavern-banner.js                # Glimmer component logic (93 lines)
    │   └── tavern-banner.hbs               # Glimmer component template (65 lines)
    └── connectors/
        └── below-site-header/
            └── tavern-banner.hbs           # Plugin outlet mount point (1 line)
```

## Directory Purposes

**`assets/`:**
- Purpose: Binary assets served by Discourse's theme asset pipeline
- Contains: `logo.png`
- Key files: `assets/logo.png`

**`common/`:**
- Purpose: Files injected into every page regardless of device type (Discourse also supports `desktop/` and `mobile/` subdirectories for platform-specific overrides, neither of which is used here)
- Contains: SCSS stylesheet, `<head>` HTML injection, post-header HTML injection
- Key files: `common/common.scss`, `common/head_tag.html`, `common/after_header.html`

**`locales/`:**
- Purpose: Internationalization string tables loaded by Discourse's I18n system
- Contains: `en.yml` — the only locale; keys namespaced under `liberty_tavern`
- Key files: `locales/en.yml`

**`javascripts/discourse/api-initializers/`:**
- Purpose: Scripts that run once at Discourse boot via `apiInitializer`; used for non-component extensions such as sidebar sections, route hooks, and service overrides
- Contains: `honored-patrons.js`
- Key files: `javascripts/discourse/api-initializers/honored-patrons.js`

**`javascripts/discourse/components/`:**
- Purpose: Glimmer components (.js logic file + .hbs template file, co-located as a pair with matching names)
- Contains: `tavern-banner.js` + `tavern-banner.hbs`
- Key files: `javascripts/discourse/components/tavern-banner.js`, `javascripts/discourse/components/tavern-banner.hbs`

**`javascripts/discourse/connectors/<outlet-name>/`:**
- Purpose: Plugin outlet connectors; the subdirectory name is the Discourse outlet name; the HBS file is the content injected at that outlet
- Contains: `below-site-header/tavern-banner.hbs`
- Key files: `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`

## Key File Locations

**Entry Points:**
- `about.json`: Theme identity, color schemes — read by Discourse installer and Admin UI
- `common/head_tag.html`: `<head>` injection — Google Fonts preconnect + stylesheet link
- `common/common.scss`: All visual styling — compiled and served on every page
- `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`: Mounts banner component on every page
- `javascripts/discourse/api-initializers/honored-patrons.js`: Registers sidebar section at boot

**Configuration:**
- `settings.yml`: All admin-editable settings with types, defaults, and descriptions

**Core Logic:**
- `javascripts/discourse/components/tavern-banner.js`: Banner data fetching, route guard, Glimmer state
- `javascripts/discourse/components/tavern-banner.hbs`: Banner template with conditional sections
- `javascripts/discourse/api-initializers/honored-patrons.js`: Patron fetch, `PatronLink` class, section registration

**Localization:**
- `locales/en.yml`: All UI strings

## Naming Conventions

**Files:**
- Kebab-case for all JavaScript and HBS files: `tavern-banner.js`, `honored-patrons.js`
- Glimmer component pairs share the exact same base name: `tavern-banner.js` + `tavern-banner.hbs`
- Connector HBS file name does not need to match the component it mounts; it is the outlet slot content

**Directories:**
- Discourse-mandated lowercase paths: `api-initializers/`, `components/`, `connectors/`
- Connector subdirectory name exactly matches the Discourse outlet name: `below-site-header/`

**SCSS:**
- BEM-style class names for theme-owned elements: `.tavern-banner`, `.tavern-banner__grid`, `.tavern-banner__title`, `.tavern-banner__cta--ghost`
- Section comments use numbered headings: `// ---- 1. Typography`, `// ---- 2. Header`

**Settings:**
- Snake_case keys in `settings.yml`: `show_homepage_banner`, `honored_patrons_group`, `trending_period`

**I18n keys:**
- Dot-namespaced under `liberty_tavern.<section>.<key>`: `liberty_tavern.sidebar.honored_patrons`, `liberty_tavern.banner.trending_now`

## Where to Add New Code

**New full-page visual override:**
- Add SCSS section to `common/common.scss` following the existing numbered section comment style
- Target Discourse's real DOM selectors; do not add HTML wrappers

**New admin-configurable setting:**
- Add entry to `settings.yml` with `type`, `default`, and `description`
- Access in JavaScript via the implicit `settings.<key>` global

**New Glimmer component:**
- Create `javascripts/discourse/components/<name>.js` (logic) and `javascripts/discourse/components/<name>.hbs` (template) as a co-located pair
- Mount via an existing outlet by adding `javascripts/discourse/connectors/<outlet-name>/<name>.hbs` containing `<<ComponentName> />`

**New plugin outlet mount:**
- Create subdirectory at `javascripts/discourse/connectors/<discourse-outlet-name>/`
- Add a `.hbs` file with the component invocation

**New sidebar section:**
- Add a new file to `javascripts/discourse/api-initializers/`
- Use `apiInitializer` + `api.addSidebarSection` pattern matching `honored-patrons.js`

**New I18n strings:**
- Add keys to `locales/en.yml` under the `liberty_tavern.*` namespace
- Access in JavaScript via `I18n.t(themePrefix("liberty_tavern.<section>.<key>"))`

**New asset (image, font file):**
- Place in `assets/`
- Reference using Discourse's asset helper or direct path

## Special Directories

**`common/`:**
- Purpose: Discourse-standard directory for cross-platform theme files
- Generated: No
- Committed: Yes

**`javascripts/discourse/`:**
- Purpose: Discourse-standard root for all theme JavaScript; the `discourse/` subdirectory is required by the resolver
- Generated: No
- Committed: Yes

**`assets/`:**
- Purpose: Binary assets served through Discourse's theme asset pipeline
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-04-26*
