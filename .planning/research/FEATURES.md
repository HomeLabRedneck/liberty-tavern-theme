# Feature Landscape — Liberty Tavern Discourse Theme

**Domain:** Discourse forum theme (visual + light JS extension)
**Researched:** 2026-04-26
**Scope:** Feasibility of the Image 1 design target (custom header, homepage banner with stats, trending strip, room cards, badges/house rules panels, honored patrons sidebar)
**Overall confidence:** HIGH for theme-system capability boundaries; MEDIUM for the live `/about.json` shape on the specific Liberty Tavern instance (couldn't fetch live; relying on documented Discourse defaults).

---

## TL;DR

Every feature in the Image 1 mockup is **achievable as a pure theme** (no plugin required). Most are **table stakes** in the Discourse theme ecosystem — there are first-party theme components from the Discourse team that solve nearly identical problems (homepage feature topics, custom sidebar sections, header logo overrides). The two areas that need the most caution are:

1. **The "Patrons Inside" (active users) stat.** Discourse does not publish "currently active" through any unauthenticated endpoint. This is the only stat that may need to be quietly dropped or redefined.
2. **Replacing the entire site header (logo + custom nav).** This is doable but it is the riskiest customization in the file because Discourse rewrites this template often. The right tool is the `home-logo-contents` wrapper outlet plus `api.headerIcons.add` / `api.registerValueTransformer("home-logo-href")` — **not** a hand-written `common/header.html` override.

The current codebase already does the hard parts (Glimmer banner, sidebar API initializer, public-endpoint data fetching). The gap is mostly polish, layout positioning, and a different header strategy.

---

## Table Stakes

These are commonly implemented in Discourse themes and have first-party documentation, official Meta tutorials, or official Discourse-team theme components solving the same problem.

| Feature | How Discourse themes do it | Confidence |
|---------|---------------------------|------------|
| **Custom site header styling** (colors, height, fonts, border) | SCSS targeting `.d-header` is a documented pattern in the Designers' Guide. The current theme already does this in `common/common.scss`. | HIGH |
| **Custom logo / replace home logo link** | `api.registerValueTransformer("home-logo-href", ...)` for the URL; the `home-logo-contents` wrapper outlet to replace the logo's contents entirely; or simply set the SVG/PNG site logo via core admin and style with SCSS. All three are documented. | HIGH |
| **Add header icons / buttons** (e.g., the search button, "Sign In" link styled as a button) | `api.headerIcons.add("name", <template>...</template>, { before: "search" })` is the documented API. Sign-in is a core Discourse element; it's already in the header for anonymous users — the work is styling, not adding. | HIGH |
| **Homepage banner above the topic list** | Multiple supported plugin outlets exist: `above-main-container`, `discovery-list-container-top`, `below-discovery-categories`, `discovery-list-controls-above`. The official `discourse-homepage-feature-component` ships with three of these as configurable positions. The current code uses `below-site-header` instead, which is why it duplicates with native homepage components — see Pitfalls. | HIGH |
| **CTA buttons in a banner** ("Pull a Stool", "House Rules") | Plain anchor tags styled as buttons. The "Pull a Stool" link to `/new-topic` is **broken** (404) — see "Achievable" below for the correct compose-route pattern. | HIGH |
| **Trending Tonight strip with 3 hot topic cards** | Already implemented. Pattern is fetch `/top.json?period=daily` (unauthenticated, public), iterate, render with `categoryBadgeHTML` helper. This is the bread-and-butter pattern for homepage components — `discourse-homepage-feature-component` does the same thing for tagged topics. | HIGH |
| **Style category list as cards** ("The Rooms" section) | Discourse already supports a `categories` page style admin setting (`Categories with Featured Topics`, `Subcategories with Featured Topics`, `Categories Boxes`, `Categories Boxes with Featured Topics`). Themes typically just restyle one of these via SCSS targeting `.category-boxes` or `.category-list`. The data (topic count, post count, color, icon, description) is already in the rendered category list — no JS fetch needed. | HIGH |
| **Custom sidebar section** (Honored Patrons) | Already implemented. Uses `api.addSidebarSection` + `BaseCustomSidebarSection` / `BaseCustomSidebarSectionLink`. This is the documented pattern (Discourse 3.0+). | HIGH |
| **Theme-driven color schemes** | `about.json` `color_schemes` is the documented mechanism. Already done. | HIGH |
| **Theme settings panel** | `settings.yml` with typed entries is the documented mechanism. Already done. | HIGH |
| **Google Fonts via head_tag** | `common/head_tag.html` is documented as the official place for `<head>` injection. Already done; the only fix needed is removing the duplicate `@import` in SCSS (already noted in PROJECT.md). | HIGH |
| **Right-column "House Rules" panel** | Static HTML/HBS rendered inside the banner component or via a separate connector. Pure-presentation, no API. | HIGH |
| **Badges grid in a sidebar/panel** | `/badges.json` is a public unauthenticated endpoint; data is already being fetched in `tavern-banner.js`. | HIGH |

---

## Achievable (Possible With Theme Code, Requires Work)

These are not out-of-the-box patterns but are within the theme system's capabilities. They need custom Glimmer components, careful outlet selection, or workarounds.

### Homepage banner positioned correctly (above topic list, not duplicated)

**What:** Banner appears once, above the categories/topic list, only on the homepage.
**Why it's tricky:** Current code uses `below-site-header` outlet, which fires on **every page**, then JS-guards via `router.currentRouteName`. This works, but it puts the banner above the entire page chrome — outside the `#main-outlet` — which can fight with Discourse's native "above main container" components and produces the duplicate-render symptom mentioned in `PROJECT.md`.
**Recommended approach:** Switch to one of the homepage-specific outlets. Best candidates:
- `above-main-container` — renders inside the main outlet, above all homepage content. Used by `discourse-homepage-feature-component` as one of three official positions.
- `discovery-list-container-top` — renders above the topic list specifically on Discovery routes. The Discourse theme tutorial uses this exact outlet for a "welcome banner" example.

**Confidence:** HIGH — this is the documented pattern for homepage-only injection.

### Stats panel with live numbers

**What:** Patrons Inside, Members, Posts Today, Open Rooms.
**Data sources (all unauthenticated public endpoints):**

| Stat | Endpoint | Field | Notes |
|------|----------|-------|-------|
| **Members** | `/about.json` | `about.stats.users_count` (or `about.user_count`) | Stable for years; this is what the public `/about` page renders. |
| **Posts Today** | `/about.json` | `about.stats.posts_7_days` is the closest documented field; `posts_1_day` exists on some versions but is not guaranteed across all Discourse releases. | MEDIUM confidence on field name; verify against the live instance before relying on it. |
| **Open Rooms** (categories) | `/site.json` (public) or `/categories.json` | Length of `categories` array, filtered for `read_restricted: false` | `/site.json` is what the Discourse JS app loads on boot; it includes the full category list with permission flags. |
| **Patrons Inside** (active right now) | **Not available unauthenticated.** | — | The `/admin/dashboard.json` "active users" count requires admin auth. There is no public "currently online" count. The topic-list pages do include a `who's online` widget for some plugins, but that's plugin territory. |

**Recommendation for "Patrons Inside":** Either:
1. Redefine the stat — show `posts_7_days` as "Patrons This Week" or `users_count` minus suspended.
2. Approximate it — count unique authors across the most recent 50 posts on `/posts.json` (public on most Discourse instances, but rate-limited and not guaranteed).
3. Drop it from the design.

I recommend option 1 (redefine) as the lowest-risk, highest-value path.

**Confidence:** HIGH for `users_count` and category count; MEDIUM for `posts_1_day`; HIGH on the conclusion that "currently online" is plugin territory.

### "Pull a Stool" CTA goes somewhere real

**What:** The button currently links to `/new-topic`, which 404s.
**Why:** `/new-topic` is not a Discourse route. The compose UI is opened via JS, not a URL.
**Recommended fix:**
- Use the documented composer route: `/new-topic?title=...&category=...` works on some instances but is also fragile.
- The robust pattern is to invoke the composer service directly: `@service composer; this.composer.openNewTopic({ category, title })`.
- Alternative: link to a specific category's "new topic" entry, e.g., `/c/general/4` and let the user click "+ New Topic" there.

**Confidence:** HIGH on the bug; HIGH on the composer-service pattern (it's the documented way).

### Custom site header replacement (logo + custom nav: Trending, Rooms, Latest at the Bar, Top Shelf)

**What:** Replace the default Discourse header with a logo + tagline + 4 custom nav links + search + Sign In.
**Why it's tricky:** A previous attempt was made and reverted (commits `721a715`, `677863f`, `dc931a8` per `PROJECT.md`). The Discourse `Designers' Guide` and `Include assets` docs both warn that "directly adding theme assets to vanilla HTML in sections like the header or after header is not supported" without a Handlebars template or the plugin API.

**Recommended approach (lowest risk, highest survivability across Discourse upgrades):**

1. **Don't replace the whole header.** Style the existing `.d-header` to match the design.
2. **Logo:** Set the site logo in core admin (Settings → Branding → Logo) and use SCSS to size/place. Optionally use `home-logo-contents` wrapper outlet if you need a logo + tagline combo (the wrapper outlet docs explicitly call this out as a valid use case).
3. **Custom nav links (Trending, Rooms, Latest at the Bar, Top Shelf):** Two options:
   - Use Discourse's built-in "top menu" admin setting (Admin → Settings → `top_menu`) which lets you reorder/hide `latest`, `top`, `categories`, etc. Rename them via I18n overrides in `locales/en.yml` (e.g., override `js.filters.latest.title` → "Latest at the Bar"). This is the lowest-effort path.
   - Add custom links via `api.headerIcons.add(...)` (documented) with an icon + label.
4. **Search button:** Already in the core header; just style it.
5. **Sign In button:** Already in the core header for anonymous users; style with SCSS.

**What to avoid:** A full `common/header.html` override is technically possible (it's listed in the documented theme structure) but:
- Discourse refactors header internals every few minor versions (the header was rewritten as a Glimmer component in 3.2+).
- An HTML override skips the plugin-outlet system entirely and won't get header icons added by other components or core features.
- This is exactly why the previous attempts in git history were reverted.

**Confidence:** HIGH — every recommendation here maps to a documented Discourse API or a documented core admin setting.

### Style category list as "Rooms" cards (with colored icon, description, topic/post counts)

**What:** Image 1 shows category cards with a colored square icon, name, description, topic count, post count.
**How:** Discourse has 4 category page styles built in:
- `categories_only`
- `categories_with_featured_topics`
- `categories_boxes` ← closest match to Image 1
- `categories_boxes_with_featured_topics`

Set this via the `desktop_category_page_style` and `mobile_category_page_style` site settings (or via `theme_site_settings` in `about.json` to bake it in with the theme — this is documented as the way to override core site settings from a theme).

The category color, name, description, topic count, and post count are all already rendered by the chosen page style. Theme work is purely SCSS targeting `.category-list .category` (or `.category-boxes .category-box` for boxes layout) to restyle.

**Confidence:** HIGH.

### "Project of the Night" featured topic card

Already implemented in `tavern-banner.hbs`. Inline styles on lines 34–36 should move to SCSS (noted in PROJECT.md).
**Confidence:** HIGH (already working, just needs cleanup).

---

## Requires a Plugin (Cannot Be Done Purely Via Theme)

Strictly speaking — and this is what `PROJECT.md` asks about — none of the Image 1 features cross this line, **except possibly "Patrons Inside" if it must mean "currently active users."**

| Feature that would need a plugin | Why |
|----------------------------------|-----|
| **True "currently active users" count on the homepage** | Requires either: (a) admin-only dashboard endpoints, (b) a Redis-backed presence channel, (c) MessageBus subscription with session tracking. None of these are exposed to unauthenticated theme code. The official `discourse-presence` plugin handles this server-side. |
| **Custom database tables / new models** | E.g., if "Honored Patrons" needed editorial curation outside Discourse's group system. Currently solved by a Discourse group, which is a theme-friendly choice. |
| **Custom routes / new pages** | E.g., a `/patrons` page with custom content. Themes can extend the Ember router via `api.modifyClass` but creating brand-new server-rendered pages is plugin work. |
| **Server-side scheduled jobs** | E.g., a "Tonight's Featured Topic" rotation that runs on a schedule. Themes are pure client-side; jobs require Sidekiq, which is plugin-only. |
| **Custom badge logic / new badge types** | Badges with custom grant rules require Ruby. Theme can only display existing badges (which is what we do). |

**None of these are in the Image 1 design.** The design is fully a theme problem.

---

## Anti-Features (Things to Explicitly Not Build)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| **Full `common/header.html` HTML override** | Discourse rewrites the header template across versions; was already attempted and reverted in this repo. Loses every header icon contributed by other components (notifications, hamburger menu, user menu). | Use `home-logo-contents` wrapper outlet + `api.headerIcons.add` + SCSS. |
| **Live "users online right now" widget** | Requires server-side presence (plugin territory); no public unauthenticated endpoint exists. | Show "Members" (`users_count`) or "Posts this week" (`posts_7_days`). Rename to "Patrons This Week" to fit the tavern metaphor. |
| **Custom router/route definitions for `/trending`, `/rooms`, `/top-shelf`** | These are aliases for things Discourse already routes (`/top`, `/categories`, `/top?period=...`). Inventing new routes means maintaining JS that duplicates core. | Use the existing Discourse routes and rename them via I18n overrides in `locales/en.yml`. The `top_menu` site setting gives you full reordering. |
| **Hardcoded category IDs in templates** | Categories on a real forum get renamed, restructured, or deleted. Hardcoding IDs creates silent breakage. | Use category slugs and look up via `this.site.categories` (already a service in the codebase). |
| **Polling endpoints for real-time updates** | Eats rate limit, drains battery. | Discourse has MessageBus for live updates; for v1 just fetch on mount. The current "fetch once" pattern in `tavern-banner.js` is correct. |
| **Custom JS for stats that the core dashboard already shows** | If admins need it, send them to `/about` (public) which already renders. | Pull from `/about.json` and style. |
| **Replacing the sidebar entirely** | The sidebar is a Glimmer surface that Discourse keeps refactoring. Honored Patrons section already works as an *additional* section. | Add sections via `api.addSidebarSection` (already done). |

---

## Feature Dependencies

```
Color scheme (about.json) ────┬──► Header styling
                              ├──► Banner styling
                              ├──► Category card styling
                              └──► Sidebar section styling

Theme settings (settings.yml) ─┬──► Banner shouldShow guard
                               ├──► Honored Patrons enable/group/count
                               └──► Trending period selection

Public REST endpoints ─────────┬──► /top.json ──► Trending strip + Featured card
                               ├──► /latest.json ──► Trending fallback
                               ├──► /badges.json ──► Badges grid
                               ├──► /groups/:name/members.json ──► Honored Patrons
                               ├──► /about.json ──► Stats panel (Members, Posts)
                               └──► /site.json or /categories.json ──► Stats panel (Open Rooms)

Plugin outlet selection ───────┬──► Banner mount position
                               └──► Determines duplication risk

Discourse JS API ──────────────┬──► api.headerIcons.add ──► Custom header icons
                               ├──► api.registerValueTransformer ──► Logo href
                               ├──► api.addSidebarSection ──► Honored Patrons
                               └──► api.renderInOutlet ──► Banner (alternative to connector file)

I18n overrides (locales/en.yml) ──► Renames core nav: "Latest" → "Latest at the Bar"
```

The critical dependency for fixing the duplication bug is **plugin outlet selection** — that's the single change that unblocks the homepage banner.

---

## MVP Recommendation (Phase Ordering Hint for Roadmap)

Treating Image 1 as the goal, the natural phase ordering is:

1. **Fix the foundation** — banner outlet, double font load, broken `/new-topic` link, inline styles. Pure cleanup, unblocks visual review.
2. **Custom header (the right way)** — `home-logo-contents` wrapper + `api.headerIcons.add` + I18n renames + SCSS for `.d-header`. No `common/header.html` file.
3. **Stats panel** — `/about.json` integration; redefine "Patrons Inside" to something achievable.
4. **Rooms (category cards)** — flip `desktop_category_page_style` to `categories_boxes`, restyle with SCSS to match Image 1 cards.
5. **Right-column panels (House Rules + Badges)** — Badges already loaded; House Rules is static HBS pulling from theme settings or I18n.
6. **Polish & accessibility** — italic gold numbers, focus states, color contrast on dark mode, skeleton loaders.

The "Honored Patrons" sidebar is already done well enough to keep as-is; only address it if `sidebar:refresh` proves flaky in production (it's an undocumented event per `PROJECT.md`).

---

## Sources

All HIGH-confidence statements are backed by Discourse's own developer documentation, fetched via Context7 (`/discourse/discourse-developer-docs` and `/discourse/discourse`):

- `docs/05-themes-components/06-theme-structure.md` — theme file layout, `common/header.html` is supported but discouraged for asset injection
- `docs/05-themes-components/01-developing-themes.md` — themes vs. plugins capabilities
- `docs/05-themes-components/03-designers-guide.md` — `.d-header` styling, navigation container, header icons
- `docs/05-themes-components/18-include-assets.md` — explicit warning that vanilla HTML asset injection in header is not supported
- `docs/05-themes-components/25-homepage-content.md` — homepage component pattern using `above-main-container` outlet
- `docs/05-themes-components/35-themeable-site-settings.md` — `theme_site_settings` in `about.json` for overriding core settings (e.g., `desktop_category_page_style`)
- `docs/07-theme-developer-tutorial/01-introduction.md` — `discovery-list-container-top` outlet for homepage banners
- `docs/07-theme-developer-tutorial/04-outlets.md` — wrapper outlets, `home-logo-contents` example
- `docs/07-theme-developer-tutorial/06-js-api.md` — `api.headerIcons.add`, `api.registerValueTransformer("home-logo-href", ...)`
- `docs/03-code-internals/13-plugin-outlet-connectors.md` — connector mechanics, wrapper outlet rules (only one active wrapper per outlet)
- `docs/03-code-internals/18-overriding-templates.md` — theme override precedence
- `docs/04-plugins/02-plugin-outlet.md` — outlet declaration syntax
- `docs/01-introduction/01-introduction.md` — themes can customize frontend; plugins can also customize backend Ruby
- `discourse-homepage-feature-component` — official Discourse-team theme component using `above-main-container`, `below-discovery-categories`, `discovery-list-controls-above` outlets

Categories/users/posts API references confirm the public REST endpoints used by the existing code (`/top.json`, `/latest.json`, `/badges.json`, `/groups/:name/members.json`).

**Confidence on `/about.json` field names:** MEDIUM — the endpoint is public and stable, but exact field names (`posts_1_day` vs. `posts_7_days`, `users_count` vs. `user_count`) vary slightly across Discourse versions. The implementation should `curl` the live `https://your-forum/about.json` once and lock to the actual field shape rather than trusting docs.

**Confidence on absence of public "active users" endpoint:** HIGH — confirmed across plugin docs, dashboard docs, and presence-plugin documentation. If this stat is required, it crosses into plugin territory.
