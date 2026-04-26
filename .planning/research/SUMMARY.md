# Research Synthesis — Liberty Tavern Discourse Theme

**Synthesized:** 2026-04-26
**Sources:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, PROJECT.md
**Project type:** Brownfield Discourse theme repair + completion (target: Image 1 design)

---

## Executive Summary

The Liberty Tavern theme is **75% built and 100% achievable as a pure theme** — no plugin work required. Every feature in the Image 1 mockup maps cleanly to a documented Discourse outlet, JS API, or SCSS pattern. The codebase already does the hard parts (Glimmer banner component, sidebar API integration, public-endpoint data fetching). What's missing is mostly correct outlet selection, a few API wirings (composer, `/about.json`), and an architectural decision about the duplicate-banner bug.

The single most important decision is **how to fix the duplicate-banner bug**, because that decision shapes Phase 1. Both fixes are complementary — apply both:
- **Fix A (STACK):** Add `"theme_site_settings": { "enable_welcome_banner": false }` to `about.json` (disables Discourse's native WelcomeBanner colliding with ours at the same outlet).
- **Fix B (ARCHITECTURE):** Move our banner mount from `below-site-header` to `discovery-list-container-top` via `api.renderInOutlet()`, and delete the connector file. The `below-site-header` outlet renders outside `#main-outlet-wrapper`, which breaks SCSS context.

---

## 1. Recommended Stack

| Component | Recommendation | Confidence |
|---|---|---|
| **Banner mount point** | `api.renderInOutlet("discovery-list-container-top", TavernBanner)` in an api-initializer; delete `connectors/below-site-header/` | HIGH |
| **Native welcome-banner conflict** | `"theme_site_settings": { "enable_welcome_banner": false }` in `about.json` | HIGH |
| **Custom header strategy** | Layered: `home-logo-contents` outlet (logo + title + tagline) + `api.headerIcons.add` (Sign In) + `.d-header` SCSS. **Do NOT** rebuild via `common/header.html` | HIGH |
| **"Pull a Stool" CTA** | `@service composer; this.composer.openNewTopic()` in a `@action`, bound to `<button>` (not `<a>`). Anonymous users → `router.transitionTo("login")` | HIGH |
| **Stats panel data** | `/about.json` — `users_count` (Members), `posts_last_day` (Posts Today), `categories.length` (Open Rooms), `active_users_last_day` (Patrons Inside proxy — no real-time count exists unauthenticated) | HIGH |
| **Rooms section** | `"theme_site_settings": { "desktop_category_page_style": "categories_boxes" }` in `about.json` + SCSS on `.category-boxes .category-box`. No JS fetch needed | HIGH |
| **Right-column layout** | Connector at `after-main-outlet` + CSS Grid override on `#main-outlet-wrapper` (Redditish-theme pattern) | HIGH |
| **Honored Patrons sidebar reactivity** | `@tracked patrons = []`; assignment auto-rerenders. **Drop** `appEvents.trigger("sidebar:refresh")` — that event does not exist | HIGH |
| **Custom nav links** | I18n overrides in `locales/en.yml` to rename core menu items + `top_menu` site setting to reorder. Fallback: `api.headerIcons.add` with `<DButton @route="...">` | HIGH |

---

## 2. Table Stakes

Non-negotiable for Image 1 fidelity:

1. Banner renders exactly once, on the homepage only, above the topic list, with correct styling.
2. "Pull a Stool" CTA opens the composer instead of 404ing.
3. Custom header is visible on every route (logo, title, tagline, search, Sign In).
4. Honored Patrons sidebar populates reliably on slow connections.
5. Stats panel shows real numbers from `/about.json`.
6. Trending Tonight strip works (already built — verify after outlet move).
7. Rooms section renders as styled cards.
8. Right-column panels (Badges + House Rules) appear on wide screens, hide on narrow.
9. No double Google Fonts load — delete `@import` in `common.scss`, keep `<link>` in `head_tag.html`.
10. No inline `style="..."` in `tavern-banner.hbs`.

---

## 3. Phase Ordering

### Phase 1 — Foundation Repair
**Why first:** Banner duplication is the most visible bug; fix confirms new outlet pattern works before other phases build on top.

1. Add `theme_site_settings.enable_welcome_banner = false` to `about.json`.
2. Move banner mount: delete `connectors/below-site-header/tavern-banner.hbs`; add `api.renderInOutlet("discovery-list-container-top", TavernBanner)` in an api-initializer. Replace `shouldShow` regex with `defaultHomepage()`.
3. Replace `/new-topic` `<a>` with `<button>` calling `this.composer.openNewTopic()`.
4. Refactor `honored-patrons.js`: remove `appEvents.trigger("sidebar:refresh")`, use `@tracked patrons = []`.
5. Delete `@import` for Google Fonts in `common/common.scss`.
6. Remove inline `style="..."` attributes in `tavern-banner.hbs` lines 34–36; move to SCSS.
7. Wire `accent_hue` into SCSS as `:root { --tavern-brass: hsl(#{$accent_hue}, 68%, 45%); }`.

### Phase 2 — Custom Header
**Why second:** Visually independent from layout grid; do after Phase 1 stabilizes the banner.

1. `api.renderInOutlet("home-logo-contents", ...)` rendering `<TavernLogo />` (image + title + tagline).
2. `api.headerIcons.add("tavern-sign-in", ...)` with `{ before: "search" }` — only when anonymous.
3. Nav links via I18n overrides in `locales/en.yml` + `top_menu` site setting.
4. SCSS: `.d-header` colors, height, border. Adjust `#main-outlet` padding-top.

**Do NOT:** `common/header.html`, `modifyClass` on the header, or `display: none` on `.d-header`.

### Phase 3 — Stats Panel + Rooms Section
1. Add `/about.json` to the `Promise.all` in `tavern-banner.js`. Map fields. Use defensive `??` reads.
2. Add `desktop_category_page_style: categories_boxes` to `about.json` `theme_site_settings`.
3. SCSS for Rooms cards (`.category-boxes .category-box`).
4. SCSS for italic gold stats numbers.
5. Parallelize existing `loadData()` AJAX via `Promise.all`.

### Phase 4 — Right-Column Layout
**Why last:** Touches `#main-outlet-wrapper` grid — highest blast radius.

1. Connector at `connectors/after-main-outlet/tavern-right-column.hbs` mounting `<TavernRightColumn />`.
2. CSS Grid on `#main-outlet-wrapper`, scoped to homepage routes. `@media (max-width: 1160px)` hides right column.
3. `<BadgesPanel />` reads from existing `/badges.json` data.
4. `<HouseRulesPanel />` static HBS from theme settings or I18n.

### Phase 5 (optional polish)
- I18n migration for hardcoded strings in `tavern-banner.hbs`.
- Module-level data cache with 5-min TTL.
- Update `about.json` `about_url` and `license_url`.
- Rename "Recent Badges Awarded" → "Most Awarded Badges".

---

## 4. Watch Out For (top 5)

### #1 — `appEvents.trigger("sidebar:refresh")` does not exist
**Fix:** `@tracked patrons = []`. Assignment triggers Glimmer autotracking. **Phase 1.**

### #2 — Banner duplication has two causes — apply both fixes
**Cause A:** Native `<WelcomeBanner />` renders at `below-site-header` when `enable_welcome_banner` is true.
**Cause B:** `below-site-header` outlet renders outside `#main-outlet-wrapper`, breaking SCSS context.
**Fix:** Both `theme_site_settings` disable + outlet move. **Phase 1.**

### #3 — Do not target `.d-header` for layout properties
**Risk:** Glimmer-header migration in Discourse 3.4+ moves classes. Only target colors, fonts, borders, height. Never `display`, `flex-direction`, or `position`. **Phase 2.**

### #4 — `/new-topic` 404s for all users
**Fix:** `composer.openNewTopic()` action on a `<button>`. Anonymous users routed to login. **Phase 1.**

### #5 — "Patrons Inside" has no real-time unauthenticated endpoint
**Fix:** Use `active_users_last_day` from `/about.json` as proxy. Rename label if needed. **Phase 3.**

---

## 5. Open Questions (verify on live instance before Phase 1)

1. **Is the duplicate caused by WelcomeBanner, outlet-scope mismatch, or both?** DevTools on live homepage: search for `welcome-banner` class and count `tavern-banner` instances.
2. **Is `enable_welcome_banner` actually true on the instance?** Check Admin → Customize → Themes settings.
3. **Exact `/about.json` field names on the live instance.** `curl https://<forum>/about.json | jq '.about.stats'`.
4. **Does the forum allow anonymous `/about.json` access?** Test from logged-out browser.
5. **Which Discourse minor version is live?** Check `/about.json` → `about.version`. Affects `.gjs` support (3.3+).

Defaults are provided for each — coding can proceed without answers, using defensive fallbacks.

---

## Sources

- **Discourse developer docs** (via Context7): `04-outlets.md`, `05-components.md`, `06-js-api.md`, `13-plugin-outlet-connectors.md`, `22-app-events-triggers.md`, `25-homepage-content.md`, `35-themeable-site-settings.md`
- **Reference themes:** `discourse-redditish-theme`, `discourse-homepage-feature-component`, `themes/horizon`
- **Live Discourse API:** `meta.discourse.org/about.json` verified 2026-04-26
- **Discourse core source:** `application.gjs`, `services/composer.js`, `routes/new-topic.js` (via `gh search code`)
- **Local codebase:** `CONCERNS.md`, `CONVENTIONS.md`, `tavern-banner.js`, `honored-patrons.js`, `common.scss`, `about.json`

---

*Research synthesis: 2026-04-26*
