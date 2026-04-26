# Technology Stack

**Analysis Date:** 2026-04-26

## Languages

**Primary:**
- SCSS - All styling via `common/common.scss` (~394 lines)
- JavaScript (ES2022+) - Component and initializer logic in `javascripts/discourse/`
- Handlebars (HBS) - Glimmer component templates in `javascripts/discourse/components/` and `javascripts/discourse/connectors/`

**Secondary:**
- HTML - Static injection files `common/head_tag.html`, `common/after_header.html`
- YAML - Theme manifest (`settings.yml`, `locales/en.yml`)
- JSON - Theme metadata and color schemes (`about.json`)

## Runtime

**Environment:**
- Discourse platform (Ruby on Rails host, client runs in browser)
- Tested against Discourse 3.2+; sidebar API requires Discourse 3.0+, `below-site-header` plugin outlet stable since 2.7

**Package Manager:**
- None — no `package.json`, `node_modules`, or lockfile. All JS dependencies are provided by the Discourse host application at runtime.

## Frameworks

**Core:**
- Ember.js — provided by Discourse host; used for routing (`@ember/service` router), template rendering, and service injection
- Glimmer — provided by Discourse host; used for the `TavernBanner` component (`@glimmer/component`, `@glimmer/tracking`)

**Testing:**
- None detected — no test framework, no test files

**Build/Dev:**
- No local build tooling. Discourse's own asset pipeline handles SCSS compilation and JS bundling when the theme is installed via Admin UI or git URL.

## Key Dependencies

**Critical:**
- `discourse/lib/api` — `apiInitializer` used in `javascripts/discourse/api-initializers/honored-patrons.js` to register sidebar section
- `discourse/lib/ajax` — `ajax()` utility used in both `honored-patrons.js` and `tavern-banner.js` for unauthenticated API calls
- `discourse/helpers/category-link` — `categoryBadgeHTML` used in `tavern-banner.js` to render category badges
- `@glimmer/component` — base class for `TavernBanner` in `javascripts/discourse/components/tavern-banner.js`
- `@glimmer/tracking` — `@tracked` decorator for reactive state in `tavern-banner.js`
- `@ember/service` — `@service` decorator for `router` and `site` injection in `tavern-banner.js`
- `@ember/template` — `htmlSafe` used in `tavern-banner.js`

**Infrastructure:**
- Google Fonts CDN — loaded via `common/head_tag.html`; fonts: Playfair Display, Spectral, Inter

## Configuration

**Environment:**
- No `.env` files; no environment variables required
- All configurable values are Discourse theme settings defined in `settings.yml` and editable via Admin → Customize → Themes → Liberty Tavern → Settings

**Theme Settings (from `settings.yml`):**
- `accent_hue` (integer, 0–360) — category accent and brass highlight hue
- `show_homepage_banner` (bool) — toggle the homepage banner
- `banner_title` (string) — headline copy
- `banner_subtitle` (string) — subheading copy
- `show_trending_strip` (bool) — toggle trending topics strip
- `show_badges_card` (bool) — toggle recent badges card
- `trending_period` (enum: all/yearly/quarterly/monthly/weekly/daily) — time window for `/top.json`
- `honored_patrons_enabled` (bool) — toggle sidebar Honored Patrons section
- `honored_patrons_group` (string, default `trust_level_4`) — Discourse group to source patrons from
- `honored_patrons_count` (integer, 1–10) — number of patrons to display

**Build:**
- No local build config. Theme is installed directly into Discourse via git URL or theme zip upload.

## Color Schemes

Two color schemes declared in `about.json` and selectable via Admin → Customize → Colors:
- **Liberty Tavern** (light): cream background `#f5ebd9`, oxblood accents `#7a1f1f`, brass highlights `#c8941a`
- **Liberty Tavern Dark**: dark background `#1a120c`, gold accents `#d4a548`

## Platform Requirements

**Development:**
- A running Discourse instance (v3.0+ for sidebar API; v3.2+ recommended)
- Public git repository for git-based installs
- No local Node.js, Ruby, or build tools required for theme development

**Production:**
- Discourse self-hosted or Discourse-managed hosting
- No dedicated server infrastructure — theme runs entirely within the Discourse platform
- All live-data endpoints (`/top.json`, `/latest.json`, `/badges.json`, `/groups/.../members.json`) must be publicly accessible (no API key required)

---

*Stack analysis: 2026-04-26*
