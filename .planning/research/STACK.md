# Stack/API Research: Discourse Theme Development

**Researched:** 2026-04-26
**Discourse target version:** 3.2+ (verified against `meta.discourse.org`, currently running `2026.4.0-latest`)
**Source priority used:** Live Discourse API responses (HIGH) > GitHub source via `gh search code` (HIGH) > Context7 `/discourse/discourse` and `/discourse/discourse-developer-docs` (HIGH) > training data (LOW, only used as cross-check)

---

## Question 1 — Custom Header Replacement

**Verdict:** There is **no single "header-contents" wrapper outlet** for replacing the entire `.d-header` in modern Discourse. The current 2024–2025 idiomatic approach is one of three, depending on how much you want to replace:

| Goal | Approach | Confidence |
|------|----------|------------|
| Replace the **logo only** (keep search/menu icons, sidebar toggle) | Wrapper outlet `home-logo-contents` via `connectors/home-logo-contents/<name>.hbs` | **HIGH** |
| Add **header icons** (search, sign-in button) without replacing them | `api.headerIcons.add(name, component, { before: "search" })` | **HIGH** |
| Add a custom **bar above or below** the header (logo + tagline + nav row) | Plugin outlet connector at `below-site-header` (or legacy `common/after_header.html`) — leave `.d-header` intact | **HIGH** |
| Fully replace `.d-header` | Hide via CSS `.d-header { display: none; }` and render your own bar in `below-site-header`. **Not officially recommended** — `.d-header` carries the search modal, hamburger menu, notification dropdown, and user menu; replacing breaks those flows unless you re-implement them. | **MEDIUM** (community pattern, no official docs endorse it) |

### Header-area outlets that actually exist (verified)

- **`home-logo-contents`** — wrapper outlet around the logo. Use `{{yield}}` to keep the original logo, omit it to fully replace. *(Source: Discourse developer-docs `07-theme-developer-tutorial/04-outlets.md` — "rendering into the 'home-logo-contents' outlet would replace the site logo with your own component")*
- **`below-site-header`** — top-level outlet that renders a `<div>` immediately after the entire header banner and before `<div id="main-outlet">`. *(Source: `frontend/discourse/app/templates/application.gjs` — verified via `gh search`)*
- **`above-main-container`** — renders inside `<div id="main-outlet">` above all page content (gated by `shouldHideScrollableContentAbove`). *(Source: same template, verified)*
- **`api.headerIcons.add/remove/reorder`** — JS API for the right-hand icon row. Place a sign-in button here with `{ before: "search" }` or similar.
- **`api.registerValueTransformer("home-logo-href", ...)`** — lets you change where the logo links without replacing the component.

### What does NOT exist (verified)

- ❌ No outlet named `header-contents` — does not appear in core templates.
- ❌ No outlet named `header-buttons` — searched core, no hits.
- ❌ No `header.html` partial that runs at the top of `.d-header`. The legacy theme files `common/header.html` and `common/after_header.html` still work but are HTML injection only (no Glimmer component support, no `@outletArgs`).

### Recommended approach for Liberty Tavern

The design target is "logo + 'The Liberty Tavern' title + tagline + 4 nav links + search button + Sign In button" rendered as a horizontal bar. This is **not** what Discourse's `.d-header` is shaped like — `.d-header` is a thin top bar. So the right architecture is:

1. **Keep `.d-header` intact** — do not try to replace it. Style it via SCSS to match the cream/oxblood palette.
2. **Optionally** replace the logo via `home-logo-contents` wrapper to render the small tavern emblem.
3. **Render the wide tavern bar** (logo + title + tagline + nav) as a Glimmer component connected to `below-site-header`. This is exactly the outlet the existing `tavern-banner.hbs` connector already targets, but the connector should render *both* a header bar and the homepage banner — or be split into two connectors at the same outlet (multiple connectors at one outlet are stacked in registration order, which is HIGH-confidence behavior).
4. **Add the Sign In button** via `api.headerIcons.add(...)` so it lives in the icon row alongside search and the user menu.

CSS-only hide-and-replace is technically possible (`display: none` on `.d-header`) but loses the search modal, notifications, user menu, and mobile hamburger — **do not do this**.

### Code skeleton

```js
// javascripts/discourse/api-initializers/header-icons.js
import { apiInitializer } from "discourse/lib/api";
import DButton from "discourse/components/d-button";

export default apiInitializer("1.13.0", (api) => {
  if (api.getCurrentUser()) return; // logged-in users get the user menu instead

  api.headerIcons.add(
    "tavern-sign-in",
    <template>
      <li>
        <DButton @icon="right-to-bracket" @label="liberty_tavern.sign_in"
                 @href="/login" class="icon btn-flat tavern-sign-in" />
      </li>
    </template>,
    { before: "search" }
  );
});
```

```hbs
{{! javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs }}
<img src={{theme-prefix "logo.png"}} alt="Liberty Tavern" class="tavern-logo" />
```

**Confidence:** HIGH for outlets and `headerIcons` API (verified in core source). MEDIUM for the recommended split between header-bar-as-`below-site-header` vs. modifying `.d-header` itself (this is a design tradeoff, not a correctness issue).

---

## Question 2 — Live Site Stats API

**Verdict:** `/about.json` is the single best public, unauthenticated endpoint for almost everything you need. It returns a `stats` object with daily/weekly/monthly/all-time counts for users, posts, topics, likes, visitors, and chat. **One stat is missing: there is no public endpoint that returns "currently online users" for anonymous callers.** Active-user counts in `/about.json` are *visit-based* (last day / 7 days / 30 days), not real-time presence.

### Verified `/about.json` response (live, 2026-04-26 from `meta.discourse.org`)

```json
{
  "users": [ /* 5 most-recent active users with id, username, name, avatar, title, last_seen_at */ ],
  "categories": [ /* every visible category with id, name, slug, color, text_color, icon, emoji, parent_category_id */ ],
  "about": {
    "stats": {
      "topics_last_day": 6,
      "topics_7_days": 134,
      "topics_30_days": 496,
      "topics_count": 64581,
      "posts_last_day": 103,
      "posts_7_days": 3438,
      "posts_30_days": 12716,
      "posts_count": 1836020,
      "users_last_day": 14,           // newly registered users
      "users_7_days": 166,
      "users_30_days": 658,
      "users_count": 65215,            // TOTAL REGISTERED MEMBERS
      "active_users_last_day": 320,    // users who visited in the last 24h — closest to "online today"
      "active_users_7_days": 1095,
      "active_users_30_days": 2201,
      "likes_last_day": 67,
      "likes_7_days": 2600,
      "likes_30_days": 9001,
      "likes_count": 1711932,
      "participating_users_last_day": 51,
      "participating_users_7_days": 372,
      "participating_users_30_days": 706,
      "visitors_last_day": 2009,
      "visitors_7_days": 3232,
      "visitors_30_days": 21552,
      "eu_visitors_last_day": 450,
      "eu_visitors_7_days": 697,
      "eu_visitors_30_days": 4493,
      "chat_messages_last_day": 24, "chat_messages_7_days": 894, "chat_messages_30_days": 3978,
      "chat_users_last_day": 3, "chat_users_7_days": 34, "chat_users_30_days": 58,
      "chat_channels_last_day": 0, "chat_channels_7_days": 6, "chat_channels_30_days": 29
    },
    "description": "...",
    "extended_site_description": "...",
    "banner_image": "...",
    "site_creation_date": "2016-02-17T07:50:40.228Z",
    "title": "Discourse Meta",
    "locale": "en",
    "version": "2026.4.0-latest",
    "https": true,
    "can_see_about_stats": true,
    "contact_url": "", "contact_email": "...",
    "moderator_ids": [...], "admin_ids": [...],
    "category_moderators": [...]
  }
}
```

### Mapping each stats panel value to a real field

| Banner label | Source | Notes |
|--------------|--------|-------|
| **"Patrons Inside" (active/online users)** | `about.stats.active_users_last_day` | Best available proxy. Counts users who visited in the last 24h. **There is no real-time "online right now" count in any public unauthenticated endpoint.** Authenticated users see live presence via MessageBus, but a theme component cannot rely on that. |
| **"Total Members"** | `about.stats.users_count` | Confirmed registered users. |
| **"Posts Today"** | `about.stats.posts_last_day` | Rolling 24h count, not calendar-day. Docs and live response agree. |
| **"Open Rooms" (active categories)** | `categories.length` from `/about.json` OR `category_list.categories.length` from `/categories.json` | `/about.json` only returns *visible* categories already filtered by permissions, so length = visible count. For an "active in last day" count, filter `/categories.json` by `topics_day > 0`. |

### Fields the existing `tavern-banner.js` doesn't currently fetch

The component already calls `/top.json`, `/latest.json`, `/badges.json`, and `/groups/.../members.json` — but **never `/about.json`**. The stats panel's "active users / total / posts today / open rooms" numbers are not wired up. They come from the same single `/about.json` request.

### Caveats

- `/about.json` is publicly visible **only when** `SiteSetting.about_page_hidden = false` (the default) and `can_see_about_stats` is true in the response. If an admin has enabled `hide_about_page` or restricted stats visibility, the endpoint may return 403 or the stats may be omitted. Build defensively: `data?.about?.stats?.users_count ?? 0`.
- Numbers are cached server-side (typically ~30 minutes per Discourse internals). Don't poll faster than ~5 minutes.
- "Active rooms" is ambiguous — clarify with stakeholder whether it means "categories that exist" (use `categories.length`) or "categories with new posts today" (use `/categories.json` and filter `topics_day > 0`).

### Other endpoints checked

- **`/site.json`** — verified live; returns notification types, post types, trust levels, groups, archetypes, post action types. **No user/post/topic counts.** Don't use for stats.
- **`/categories.json`** — verified live; per-category fields include `topic_count`, `post_count`, `topics_day`, `topics_week`, `topics_month`, `topics_year`, `topics_all_time`. Useful for room-card population.
- **`/directory_items.json?period=daily&order=likes_received`** — verified live; returns top contributors. Useful for "Honored Patrons" alternative if the group-based approach proves fragile.
- **`/session/current.json`** — returns 200 empty for anonymous; otherwise current user. Not useful for site-wide stats.

**Confidence:** HIGH (every field above was verified against a live Discourse 2026.4 instance on 2026-04-26).

---

## Question 3 — `below-site-header` Position vs. Native Welcome Banner

**Verdict:** `below-site-header` renders **immediately after `.d-header` and *before* `<div id="main-outlet">`**. It is **above** Discourse's homepage list, but the native "welcome-banner" component can also render at `below-site-header` — and that is the most likely cause of the duplicate-content bug described in PROJECT.md.

### Verified position (from `frontend/discourse/app/templates/application.gjs`)

```hbs
{{! ... .d-header rendered above ... }}

<PluginOutlet
  @name="below-site-header"
  @connectorTagName="div"
  @outletArgs={{lazyHash currentPath=@controller.router._router.currentPath ...}} />

{{#if (welcome-banner-condition) }}
  <WelcomeBanner />        {{! ← native welcome banner — see below }}
{{/if}}

<div id="main-outlet">
  {{#unless @controller.shouldHideScrollableContentAbove}}
    <PluginOutlet @name="above-main-container" @connectorTagName="div" />
    {{#unless @controller.isCurrentAdminRoute}}
      <BlockOutlet @name="main-outlet-blocks" />
    {{/unless}}
  {{/unless}}
  ...
</div>
```

So the vertical order on the homepage is:

1. `.d-header` (the thin top bar)
2. **`below-site-header` outlet** ← `<TavernBanner />` mounts here
3. Native `<WelcomeBanner />` (conditional)
4. `<div id="main-outlet">`
5.   `above-main-container` outlet
6.   `<BlockOutlet @name="main-outlet-blocks" />` (renders the topic list / discovery page)

### The "Welcome back" / "Welcome to" content is the native WelcomeBanner

This component was added to Discourse in the 2025-Q1 timeframe (verified by migrations referencing `enable_welcome_banner` site setting and a `migrate_advanced_search_banner_to_welcome_banner.rake` task). Critically:

- It is gated by the **theme site setting `enable_welcome_banner`** (default `false` for upgrades, `true` for new sites since 2025-03).
- It has a **location setting** with two valid values: `below_site_header` and `above_main_container` — verified by the SCSS file `themes/horizon/scss/welcome-banner.scss` and integration tests at `frontend/discourse/tests/integration/components/welcome-banner-test.gjs`.
- When location is `below_site_header`, it renders **right next to** Liberty Tavern's banner — and *both* are visible. **This is exactly the "banner appears twice" bug from PROJECT.md.**

### Fix options

**Option A (recommended): Disable the native welcome banner in `about.json`**

Use Discourse's `theme_site_settings` mechanism (verified in `developer-docs/05-themes-components/35-themeable-site-settings.md`):

```json
{
  "name": "Liberty Tavern",
  "component": false,
  "theme_site_settings": {
    "enable_welcome_banner": false
  },
  "color_schemes": { ... }
}
```

This sets the value once at install and admins can still flip it back if they want. **Confidence: HIGH** (mechanism documented in official theme dev docs).

**Option B: Move TavernBanner to `above-main-container`**

This places the tavern banner *below* the native welcome banner inside `#main-outlet`. Native banner appears first, custom banner second — still duplicate-feeling content but no overlap collision. Use only if you want both visible.

**Option C: Hide the native banner via CSS**

```scss
.welcome-banner { display: none; }
```

Crude but works. Inferior to Option A because the `<WelcomeBanner />` component still mounts, fetches data, and runs its viewport-tracking logic.

### Outlets ABOVE `below-site-header`

There is **no plugin outlet between `.d-header` and `below-site-header`** that ships in core. Inside `.d-header` itself, only `home-logo-contents` (wrapper) and the `headerIcons` API exist. If you need content *between* the header and the welcome banner, `below-site-header` is the highest available point in core.

The legacy `common/header.html` and `common/after_header.html` files inject HTML strings into `.d-header` (header.html) or just below it (after_header.html). These predate the modern outlet system and don't support Glimmer components or outlet args. **Don't use them for new code** — use `below-site-header` connectors.

**Confidence:** HIGH — the application.gjs structure was directly read from Discourse main, and the native WelcomeBanner location enum was verified via SCSS class names and integration test asserts.

---

## Question 4 — Composer API for "New Topic"

**Verdict:** Inject the composer service and call `this.composer.openNewTopic({ title?, body?, category?, tags?, formTemplate? })`. The current `/new-topic` link in `tavern-banner.hbs` is broken because **`/new-topic` is a route, but only routes prefixed with `/new-topic` work via `routes/new-topic.js`** (which expects query params like `?title=...&category=...`). Direct navigation to bare `/new-topic` does in fact resolve (it routes through `frontend/discourse/app/routes/new-topic.js`), so the 404 reported in CONCERNS.md is more likely a config issue, but the proper composer-driven approach is far better.

### Verified canonical pattern (from Discourse main, multiple call sites)

`frontend/discourse/app/services/composer.js`:

```js
@action
async openNewTopic({ title, body, category, tags, formTemplate } = {}) {
  const readOnlyCategoryId = !category?.canCreateTopic ? category?.id : null;
  tags = await this.filterTags(tags);
  // ... opens composer in CREATE_TOPIC mode
}
```

Real call sites in core (all verified via `gh search code "openNewTopic" --repo discourse/discourse`):

```js
// frontend/discourse/app/controllers/discovery/categories.js
this.composer.openNewTopic();

// frontend/discourse/app/controllers/discovery/list.js
this.composer.openNewTopic({
  category: this.createTopicTargetCategory,
  tags: [this.model.tag?.name, ...(this.model.additionalTags ?? [])].filter(Boolean),
});

// themes/horizon/javascripts/discourse/components/sidebar-new-topic-button.gjs
this.composer.openNewTopic({
  category: this.createTopicTargetCategory,
  tags: this.tag?.name,
});

// frontend/discourse/app/components/admin-onboarding/banner.gjs
this.composer.openNewTopic({
  title: i18n(`admin_onboarding_banner.start_posting.icebreakers.${topicKey}.title`),
  // ...
});
```

### Recommended fix for `tavern-banner.hbs` "Pull a stool" CTA

**Step 1 — inject the service in `tavern-banner.js`:**

```js
import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";

export default class TavernBanner extends Component {
  @service router;
  @service site;
  @service composer;        // ← add this
  @service currentUser;     // ← optional, for guard

  @action
  pullAStool() {
    if (!this.currentUser) {
      // Anonymous: send to login (Discourse will return after sign-in)
      window.location.href = "/login";
      return;
    }
    this.composer.openNewTopic();
    // Or specify a default category:
    // this.composer.openNewTopic({ category: this.site.categories.findBy("slug", "the-bar") });
  }
}
```

**Step 2 — wire the template:**

```hbs
{{! tavern-banner.hbs }}
<button type="button" class="btn btn-primary tavern-cta" {{on "click" this.pullAStool}}>
  {{i18n (theme-prefix "liberty_tavern.banner.cta")}}
</button>
```

(Note: change from `<a href="/new-topic">` to a `<button>` because there's no URL — this is an action.)

### Why not just fix the URL?

You could keep an `<a>` and use `/new-topic?title=&category_id=N`, which is what `frontend/discourse/app/routes/new-topic.js` consumes. But:
- Route-based composer opens cause a full page transition first, which flashes the topic list.
- The route requires either a logged-in user or anonymous-posting permissions; otherwise it bounces to `/login`. Handling this in JS gives you a smoother failure mode.
- The composer service approach is what every Discourse-built button uses (see horizon theme, admin-onboarding, discovery controllers).

### Caveats

- `composer.openNewTopic()` exists in Discourse 3.0+; the `formTemplate` parameter was added later (likely 3.2+). If you don't pass it, you don't need to worry.
- For anonymous users with `allow_anonymous_posting` disabled, `openNewTopic()` will trigger Discourse's standard "log in to reply" dialog automatically — which is the right UX. You don't need to guard for it.
- Don't import `Composer.CREATE_TOPIC` constants directly — that's an older controller-level API and no longer the recommended path.

**Confidence:** HIGH — verified against multiple call sites in current Discourse main and the canonical Horizon theme.

---

## Cross-cutting recommendations for the Liberty Tavern theme

1. **Add a `theme_site_settings` block to `about.json`** to disable `enable_welcome_banner`. This is the single highest-leverage fix — it removes the duplicate-content bug at the source.

2. **Inject the `composer` service in `tavern-banner.js`** and replace the `/new-topic` link with `{{on "click" this.pullAStool}}`. Removes the broken-link bug.

3. **Don't replace `.d-header`.** Style it via SCSS (already done in `common/common.scss`). Optionally swap the logo via a `home-logo-contents` connector. Add the Sign In button via `api.headerIcons.add(...)`.

4. **Render the wide tavern bar (logo + title + tagline + nav) inside the existing `below-site-header` connector**, immediately above the homepage banner content. They can be siblings inside one Glimmer component or split into two outlet connectors at the same outlet.

5. **Wire up the stats panel via `/about.json`** — fetch in parallel with `/top.json` and `/badges.json` using `Promise.all`. Map fields per the table in Question 2.

6. **Treat `sidebar:refresh` as fragile** (already noted in CONCERNS.md). The Honored Patrons section should be migrated to a tracked Glimmer component rather than relying on an undocumented appEvent.

---

## Confidence Summary

| Question | Confidence | Reasoning |
|----------|------------|-----------|
| Q1 — Header customization | HIGH for outlets/APIs that exist; MEDIUM for "best" replacement strategy | Official outlets verified in dev docs and source; replacement strategy is a design choice |
| Q2 — Live stats API | HIGH | All fields verified against live `meta.discourse.org/about.json` response on 2026-04-26 |
| Q3 — `below-site-header` position | HIGH | Read directly from `application.gjs` in current Discourse main; conflict mechanism verified via WelcomeBanner location enum |
| Q4 — Composer API | HIGH | Pattern verified across 7+ call sites in current Discourse main and the Horizon theme |

---

## Sources

- Live `/about.json` response from `meta.discourse.org` (2026-04-26)
- Live `/site.json`, `/categories.json`, `/directory_items.json` from `meta.discourse.org`
- Discourse main repo `frontend/discourse/app/templates/application.gjs` (verified via `gh search code`)
- Discourse main repo `frontend/discourse/app/services/composer.js` (verified via `gh search code`)
- Horizon theme `javascripts/discourse/components/sidebar-new-topic-button.gjs` (canonical reference)
- Discourse developer-docs `07-theme-developer-tutorial/04-outlets.md` (Wrapper Outlets, `home-logo-contents`)
- Discourse developer-docs `07-theme-developer-tutorial/06-js-api.md` (`api.headerIcons.add`)
- Discourse developer-docs `05-themes-components/35-themeable-site-settings.md` (`theme_site_settings`)
- Discourse developer-docs `05-themes-components/06-theme-structure.md` (legacy `common/after_header.html`)
- Discourse developer-docs `03-code-internals/13-plugin-outlet-connectors.md` (wrapper outlets, `{{yield}}`)

*All Context7-fetched docs were retrieved 2026-04-26 via `npx ctx7@latest docs /discourse/discourse <query>` and `/discourse/discourse-developer-docs <query>`.*
