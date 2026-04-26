# External Integrations

**Analysis Date:** 2026-04-26

## APIs & External Services

**Google Fonts CDN:**
- Service: Google Fonts (fonts.googleapis.com / fonts.gstatic.com)
- Purpose: Loads Playfair Display (display/headline), Spectral (body serif), and Inter (UI/sans) typefaces
- Integration point: `common/head_tag.html` — three `<link>` tags with preconnect hints
- Auth: None — public CDN
- Fallback: CSS `font-family` stacks in `common/common.scss` fall back to `Times New Roman`, `Georgia`, and `-apple-system` / `BlinkMacSystemFont` if Google Fonts is unavailable

## Discourse Internal REST API (Public Endpoints)

All calls are unauthenticated, read-only, and use Discourse's bundled `ajax()` helper from `discourse/lib/ajax`. No API key is required. These are calls to the same Discourse instance the theme runs on (same-origin).

**`/top.json`**
- Used in: `javascripts/discourse/components/tavern-banner.js`
- Purpose: Fetches trending topics for the homepage banner "Trending Tonight" strip and "Project of the Night" feature card
- Parameters: `?period={trending_period}` (controlled by theme setting `trending_period`)
- Fallback: If response has fewer than 4 topics, falls back to `/latest.json`

**`/latest.json`**
- Used in: `javascripts/discourse/components/tavern-banner.js`
- Purpose: Supplemental topic source when `/top.json` returns fewer than 4 topics
- Parameters: None
- Auth: None

**`/badges.json`**
- Used in: `javascripts/discourse/components/tavern-banner.js`
- Purpose: Fetches site-wide badge definitions including `grant_count`; the top 4 enabled badges by grant count populate the "Recent Badges Awarded" card
- Parameters: None
- Auth: None

**`/groups/{groupName}/members.json`**
- Used in: `javascripts/discourse/api-initializers/honored-patrons.js`
- Purpose: Fetches members of the configured Discourse group to populate the "Honored Patrons" sidebar section
- Parameters: `?limit={honored_patrons_count}&order=added_at&asc=false`
- Group name: Controlled by theme setting `honored_patrons_group` (default: `trust_level_4`)
- Auth: None — returns public group member data; private groups will return empty or error (caught silently)
- Caching: Promise is cached per page load (re-fetched on navigation)

## Data Storage

**Databases:**
- None — the theme has no database of its own. All persistent data (topics, badges, users, groups) lives in the host Discourse instance's database and is read via public API endpoints.

**File Storage:**
- `assets/logo.png` — static logo image committed to the theme repository; served by Discourse's asset pipeline after upload

**Caching:**
- In-memory only: `honored-patrons.js` caches the `/groups/.../members.json` promise in a module-scoped variable (`patronsPromise`) for the lifetime of the page. No localStorage, IndexedDB, or service worker caching.

## Authentication & Identity

**Auth Provider:**
- None — the theme performs no authentication itself
- All API calls are unauthenticated public endpoints; the theme inherits the logged-in session context automatically from the Discourse host (Discourse's own cookie-based auth applies to all same-origin requests)
- If `/groups/.../members.json` requires auth (private group), the fetch silently returns an empty array

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Datadog, or similar integration

**Logs:**
- Single `console.warn` in `tavern-banner.js` `loadData()` catch block: logs "Liberty Tavern banner: failed to load data" with the error object
- All other failures (honored patrons, individual topic fetch fallbacks) are silent — caught with `.catch(() => null)` or `.catch(() => [])` patterns

## CI/CD & Deployment

**Hosting:**
- Discourse platform (self-hosted or Discourse-managed)
- Theme is installed via Admin → Customize → Themes → Install → "From a git repository"

**CI Pipeline:**
- None detected — no GitHub Actions, CircleCI, or similar workflow files in the repository

**Update mechanism:**
- In-Discourse git pull: Admin clicks "Update" on the theme page; Discourse re-fetches from the configured git URL

## Environment Configuration

**Required env vars:**
- None — the theme requires no environment variables

**Secrets location:**
- No secrets. No API keys, tokens, or credentials of any kind are used.

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None — the theme makes only read-only GET requests to same-origin Discourse endpoints

## Font Details

| Family | Weights Loaded | Usage |
|---|---|---|
| Playfair Display | 700, 900 (normal + italic) | Headlines, titles, display text |
| Spectral | 400, 500, 600 (normal + italic) | Body text, sidebar links, topic descriptions |
| Inter | 400, 500, 600, 700 | UI elements, buttons, nav pills, stats |

Loaded URL (in `common/head_tag.html` and also imported in `common/common.scss`):
`https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,700;1,900&family=Spectral:ital,wght@0,400;0,500;0,600;1,400;1,500&family=Inter:wght@400;500;600;700&display=swap`

Note: Google Fonts is loaded twice — once via `<link>` tags in `common/head_tag.html` (fast preconnect path) and once via `@import url(...)` inside `common/common.scss`. The `<link>` path is preferred for performance; the `@import` is redundant but harmless.

---

*Integration audit: 2026-04-26*
