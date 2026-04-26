# Domain Pitfalls

**Domain:** Discourse 3.2+ custom theme (Glimmer components, plugin outlets, sidebar API, SCSS)
**Researched:** 2026-04-26
**Sources:** Context7 (`/discourse/discourse`, `/discourse/discourse-developer-docs`), local codebase static analysis. WebSearch and WebFetch were not available in this environment, so claims about Discourse Meta community threads are flagged LOW confidence; Context7-backed claims about the official developer docs are HIGH confidence.

---

## Critical Pitfalls (Phase 1 — blocking)

### Pitfall 1: `/new-topic` is a route, but it requires query parameters and the user must be logged-in and able to post

**Warning signs:**
- Anonymous users (or users without `create_topic` permission in the default category) clicking the CTA see a permission error, not the composer.
- Logged-out users hit the login flow first, then sometimes land on `/latest` instead of the composer.
- The link "appears to 404" depending on which Discourse build you are on — older builds did not register `/new-topic` as a top-level route, and SSO/login redirects can drop the path during the round-trip.

**Root cause:**
Discourse does have a `/new-topic` route, but it is implemented as a *redirect handler* that opens the composer if-and-only-if it can resolve a category and the current user has permission to post there. Without the right query parameters, the route falls through to a 404-feeling state. The canonical, documented way to programmatically open the composer is the **composer service**, not a URL.

A bare `<a href="/new-topic">` is fragile because:
1. It depends on the user being logged in.
2. It does not specify a category, so the composer cannot pre-select one.
3. It triggers a full Ember route transition rather than a modal — slower UX and can break if the route name changes.

**Fix (specific):**
Replace the inline `<a href="/new-topic">` in `tavern-banner.hbs` with a Glimmer button bound to an `@action` that calls the composer service. In `tavern-banner.js`:

```js
import { action } from "@ember/object";
import { service } from "@ember/service";
// Composer model constants
import Composer from "discourse/models/composer";

export default class TavernBanner extends Component {
  @service composer;
  @service currentUser;
  @service router;

  @action
  pullAStool() {
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    this.composer.openNewTopic({
      // Pre-select the "Tavern Talk" category if it exists, otherwise omit.
      // categoryId: this.site.categories.findBy("slug", "tavern-talk")?.id,
      title: "",
      body: "",
      // draftKey/archetype default to a normal topic; do not set unless needed.
    });
  }
}
```

In `tavern-banner.hbs`:

```hbs
<DButton
  @action={{this.pullAStool}}
  @translatedLabel={{i18n (theme-prefix "liberty_tavern.banner.cta")}}
  class="tavern-banner__cta"
/>
```

The `composer` service exposes `openNewTopic({ categoryId, title, body, tags })` as the public, documented entry point. It handles login redirects, permission checks, and pre-population in one call.

**As a fallback** (if you want to keep a plain link for SEO / right-click "Open in new tab" behavior), use the URL form `/new-topic?title=Hello&category=general` — this *is* a real Discourse route handler that pre-fills the composer. But for the on-page CTA, the service call is correct.

**Confidence:** HIGH for the composer service path (Context7 / `composer:open` app event documented in `/docs/developer-guides/docs/03-code-internals/22-app-events-triggers.md`). MEDIUM for the `/new-topic?title=...` URL form (well-known community pattern; not surfaced by Context7 in this run).

**Phase:** 1 — the CTA is a primary call-to-action on the homepage banner; it must work.

---

### Pitfall 2: `appEvents.trigger("sidebar:refresh")` is undocumented and silently no-ops

**Warning signs:**
- The Honored Patrons sidebar section shows "no items" / blank / collapsed even though the `/groups/{name}/members.json` request returns data (verify in DevTools → Network).
- On a hard reload, the section sometimes populates and sometimes does not — race condition between sidebar mount and AJAX resolution.
- No console error; the sidebar simply stays empty.

**Root cause:**
There is **no `sidebar:refresh` app event** in the Discourse codebase. Context7 search of the developer docs surfaces `REFRESH_USER_SIDEBAR_CATEGORIES_SECTION_COUNTS_APP_EVENT_NAME` (a different event, only for category counts), but no general `sidebar:refresh`. The current code triggers an event that nobody listens for.

The reason the section appears to work *sometimes* is incidental: `api.addSidebarSection` re-evaluates the `links` getter on its own internal triggers (route change, sidebar collapse/expand). If the AJAX resolves before any of those triggers fire, the section paints empty and stays empty.

The fundamental issue is that `addSidebarSection` was designed around **synchronous data sources** (the user's tracked categories, tags, etc., already in the Ember store). Pushing async data through it requires the sidebar section's internal state to be a `@tracked` field so Ember's autotracking forces a re-render when assignment happens.

**Fix (specific):**
Replace the imperative `_patrons = []` field + manual `trigger` with a `@tracked` field. The tracking system will cause the `links` getter to recompute and the sidebar to re-render automatically.

```js
import { tracked } from "@glimmer/tracking";

return class extends BaseCustomSidebarSection {
  @tracked patrons = [];

  constructor() {
    super(...arguments);
    loadPatrons().then((users) => {
      this.patrons = users; // tracked assignment → links getter re-runs
    });
  }

  get links() {
    return this.patrons.slice(0, limit).map((u) => new PatronLink({ user: u }));
  }
  // ... rest unchanged, drop the appEvents.trigger("sidebar:refresh") block
};
```

Remove the entire `if (api.container) { ... }` block. It does nothing useful and will continue to "not work" silently if Discourse never adds such an event.

**Confidence:** HIGH. Context7 lookup of the official developer docs lists every documented app event; `sidebar:refresh` is not present. The recommended pattern of using `@tracked` on sidebar section instances matches the broader Discourse guidance on Glimmer components ("use `@tracked` to mark fields that should trigger a DOM re-render", `/docs/07-theme-developer-tutorial/05-components.md`).

**Phase:** 1 — Honored Patrons is a stated feature; it must work reliably.

---

### Pitfall 3: Banner duplication from `below-site-header` outlet conflicting with native homepage components

**Warning signs:**
- Banner content renders twice on the homepage: once unstyled at the top, once styled in the correct position.
- The unstyled copy appears above any "Welcome back" banner.
- Disabling the theme makes the duplicate disappear.

**Root cause (most likely):**
`below-site-header` is a wrapper outlet that renders **on every route**, not just the homepage. `tavern-banner.js` already gates rendering with `shouldShow` via `/^discovery\./`, so the empty `else` branch should hide the banner outside of discovery. **But** if the connector file in `connectors/below-site-header/` is a *legacy* connector (a bare `.hbs` template not gated by an `@if` on `shouldShow`), it can render an unstyled fragment of the banner template before the Glimmer component mounts and gates itself.

The other common cause: the `below-site-header` outlet sits *above* the Discourse "Welcome topic / curated content" banner that the homepage renders by default. When a theme injects a homepage-specific banner via `below-site-header`, the result is two stacked banners visually competing. Discourse documents `discovery-list-container-top` as the preferred outlet for homepage banners (see `/docs/07-theme-developer-tutorial/04-outlets.md`) — that outlet only fires on the discovery routes, removing the need for a route guard at all.

**Fix (specific):**
1. Move the banner from `connectors/below-site-header/` to `connectors/discovery-list-container-top/`. This outlet is route-scoped, so the `shouldShow` getter can be simplified to checking only `settings.show_homepage_banner`.
2. Convert the connector file to a `.gjs` module that uses `api.renderInOutlet(...)` from an api-initializer rather than a bare template file. This gives a single registration point and avoids the legacy-connector double-mount class of bug.
3. Audit for any leftover banner HTML in `head_tag.html` or `header_tag.html` — those run on every page and any banner markup there will appear unstyled at the top of the document. Looking at the symptoms ("unstyled plain text at top of page"), this is the second-most-likely culprit after the outlet choice.

**Confidence:** MEDIUM. The `discovery-list-container-top` recommendation is HIGH (Context7-confirmed). The exact root cause of the duplication in this codebase is MEDIUM — could be either (a) a duplicate connector mount, (b) a stray template fragment in a `*_tag.html` file, or (c) the outlet rendering on multiple pages. Phase 1 should reproduce in DevTools before implementing.

**Phase:** 1 — the banner is the "entire point of having a custom theme" per `PROJECT.md`; duplication is a blocker.

---

### Pitfall 4: CSS class coupling to Discourse internals (`.d-header`, `.sidebar-wrapper`, etc.) is brittle across 3.2+ point releases

**Warning signs:**
- After upgrading the host Discourse instance, the header turns transparent / loses its custom background.
- Sidebar styling breaks while functionality still works.
- Search dropdown unstyled / wrong width.
- DevTools shows the targeted class (e.g. `.d-header`) is no longer in the DOM, replaced by `.d-header-wrap` or a child `.glimmer-header`.

**Root cause:**
Discourse has been modernizing its frontend by replacing classic Ember components with Glimmer components throughout the 3.x series. The header in particular has gone through a `glimmer_header` experimental flag → default rollout that adds new wrapping elements and moves some CSS classes one level deeper. Specific known shifts:

- `.d-header` is still present, but its child `.contents` may now sit inside an additional wrapper.
- `.sidebar-wrapper` exists, but rendered differently when the sidebar is in a "hamburger" responsive state.
- `.search-menu` has been refactored multiple times; the inner panel class names changed.
- `.d-header-icons` is stable but the `<li>` structure inside it has been simplified.

The Discourse developer docs explicitly recommend `modifyClass` and direct CSS targeting "as a last resort" because "core's code can change at any time" (`/docs/03-code-internals/14-modifyclass.md`).

**Fix (specific):**
Cannot avoid targeting internal classes for theming; that is the nature of a Discourse theme. But mitigate the fragility:

1. **Add a section banner to `common.scss` per Discourse-internal selector group**, noting the Discourse version where the selector was last verified. Example:

   ```scss
   // ---- Discourse header (verified against 3.4.x; re-check on upgrade) ---
   .d-header { ... }
   ```

2. **Prefer CSS variables over re-styling the whole element**. Discourse exposes CSS variables (`--header-background`, `--primary`, `--secondary`, etc.). Setting `:root { --header-background: var(--tavern-cream); }` survives DOM restructuring; setting `.d-header { background: ...; }` does not.

3. **Avoid layout overrides on internal selectors.** Restyling colors, fonts, and borders is robust. Changing `display`, `position`, `flex-direction`, or removing children is what breaks. The current codebase's convention ("Restyles Discourse's real DOM. No layout overrides outside [the banner]") is correct — keep it.

4. **Subscribe to the Discourse `core-changes` Meta tag** before each upgrade and grep the changelog for the selectors used in `common.scss`. Build a one-page upgrade checklist.

**Confidence:** HIGH that `.d-header`, `.sidebar-wrapper`, `.search-menu` exist and are the right targets (Context7-confirmed in the official designers guide, `/docs/05-themes-components/03-designers-guide.md`). MEDIUM on the specific 3.x refactor history — Context7 surfaced the existence of `glimmer_header` work but not a precise list of class renames.

**Phase:** 1 for adding the version-comment audit pass; ongoing maintenance thereafter.

---

## Moderate Pitfalls (Phase 2 — important)

### Pitfall 5: Double Google Fonts load (`<link>` + `@import`)

**Warning sign:** Network tab shows two requests to `fonts.googleapis.com/css2?...` per page load.

**Root cause:** The `@import url(...)` at the top of `common/common.scss` and the `<link rel="stylesheet">` in `common/head_tag.html` resolve the same URL.

**Fix:** Delete the `@import` line in `common/common.scss`. Keep the `<link>` in `head_tag.html` because:
- `<link>` in head is parser-blocking but parallel-loadable; `@import` inside CSS is serial and blocks render until the parent stylesheet finishes parsing. The `<link>` path is faster.
- The `head_tag.html` version also has the `preconnect` hint to `fonts.gstatic.com`, which the `@import` cannot do.

**Confidence:** HIGH (web performance best practice; multiple authoritative sources).

**Phase:** 2 — performance/polish.

---

### Pitfall 6: Inline `style="..."` in `tavern-banner.hbs` cannot be overridden

**Warning sign:** Changing the SCSS for the featured-card title in `common.scss` does nothing visually; only editing the template applies.

**Root cause:** Inline styles have higher specificity than any class-based selector that does not use `!important`.

**Fix:** Remove the two `style="..."` attributes (`tavern-banner.hbs` lines 34–36). Move the equivalent declarations into the existing `.tavern-banner` block in `common.scss`, scoped to a class:

```scss
.tavern-banner__featured-link { color: inherit; text-decoration: none; }
.tavern-banner__featured-title { font-size: 1.4rem; line-height: 1.3; }
```

Then in `tavern-banner.hbs`:

```hbs
<a class="tavern-banner__featured-link" href={{this.topicUrl this.featured}}>
  <h3 class="tavern-banner__featured-title">{{this.featured.title}}</h3>
</a>
```

**Confidence:** HIGH (CSS specificity is well-defined).

**Phase:** 2.

---

### Pitfall 7: `accent_hue` setting is dead code

**Warning sign:** Admin changes the slider; nothing visually changes.

**Root cause:** Setting is declared in `settings.yml` but never referenced in `common.scss`. SCSS interpolation of theme settings happens via `$accent_hue` (or via `:root` CSS variables built from settings).

**Fix:** Two options.
- **Wire it up (recommended)**: In `common.scss`, add at the top of `:root`:
  ```scss
  :root { --tavern-brass: hsl(#{$accent_hue}, 68%, 45%); }
  ```
  Then replace hardcoded brass hex values (`#c8941a`) with `var(--tavern-brass)`. Keep one fallback `--tavern-brass: #c8941a;` higher in the cascade in case the SCSS variable isn't injected.
- **Remove it**: Delete the `accent_hue` block from `settings.yml` and the corresponding key from `locales/en.yml`. Cleaner if no admin actually wants to change the brass hue.

The codebase concerns document already proposes the wiring fix; recommend it because the setting is already user-discoverable in admin UI.

**Confidence:** HIGH (SCSS interpolation of theme settings is standard Discourse).

**Phase:** 2.

---

### Pitfall 8: `shouldShow` route detection regex is brittle

**Warning sign:** Banner disappears on the homepage after a Discourse upgrade. `router.currentRouteName` in the browser console returns something like `discovery.latest` (works) or `home` / `discovery-latest` (fails).

**Root cause:** The current regex `/^discovery\./` matches `discovery.latest`, `discovery.categories`, `discovery.top`, etc. — Discourse's nested route naming. It will NOT match if Discourse changes to flat names (`discovery-latest`) or moves the homepage to a different route family.

**Fix:** Two layers of defense.
1. Switch to `discovery-list-container-top` as the mount outlet (Pitfall 3) — that outlet only renders inside the discovery route family by construction, so the regex becomes redundant.
2. If keeping a manual gate for any reason, also accept the homepage route by name: `route.startsWith("discovery.") || route === "discovery.index"`.

**Confidence:** MEDIUM. Context7 confirms `discovery-list-container-top` is the recommended homepage banner outlet but did not enumerate every current route name.

**Phase:** 2 (combined with Pitfall 3).

---

### Pitfall 9: Sequential AJAX in `loadData()` chains three round trips

**Warning sign:** Banner shows the loading state for 1–3 seconds on slow connections. Network tab waterfall shows `/top.json` → `/latest.json` → `/badges.json` strictly serial.

**Root cause:** `loadData()` uses `await` with conditional fallback, forcing strict ordering even when parallelization is safe. `/badges.json` does not depend on the topic data.

**Fix:** Run the independent calls in parallel:

```js
const [topRes, badgeRes] = await Promise.all([
  ajax(`/top.json?period=${period}`).catch(() => null),
  ajax("/badges.json").catch(() => null),
]);

let topics = topRes?.topic_list?.topics || [];
if (topics.length < 4) {
  const latestRes = await ajax("/latest.json").catch(() => null);
  // ... merge as before
}
// process topics + badgeRes
```

**Confidence:** HIGH (basic Promise.all parallelism).

**Phase:** 2.

---

## Minor Pitfalls (Phase 3 — polish)

### Pitfall 10: Hardcoded display strings bypass the i18n system

**Warning sign:** `locales/en.yml` defines `liberty_tavern.banner.trending_now` etc., but a grep of the templates shows raw strings ("Trending Tonight", "Recent Badges Awarded", "Pull a stool") in `tavern-banner.hbs`.

**Root cause:** Template authors hardcoded copy directly. The locale file became dead weight.

**Fix:** Replace each raw string with `{{i18n (theme-prefix "liberty_tavern.banner.<key>")}}` (Context7-verified pattern, `/docs/05-themes-components/14-localizable-strings.md`). Keys to wire up are already in `locales/en.yml`.

**Confidence:** HIGH.

**Phase:** 3.

---

### Pitfall 11: README documents `/user-badges.json` but code calls `/badges.json`

**Warning sign:** Documentation drift; "Recent Badges Awarded" panel shows definition popularity, not recent grant activity.

**Root cause:** Endpoint switched during development without a README update.

**Fix:** Either update README + heading copy to "Most Awarded Badges" (matches behavior), or implement true recent-grants by paginating `/user_badges.json` per user — but the latter is expensive without an API key. Recommend renaming.

**Phase:** 3.

---

### Pitfall 12: `about.json` placeholder GitHub URLs

**Warning sign:** Clicking "About this theme" in admin → 404 on `your-org/liberty-tavern-theme`.

**Fix:** Update `about_url` and `license_url` to the real repo, or remove the keys.

**Phase:** 3.

---

### Pitfall 13: No caching for banner data; refetch on every navigation

**Warning sign:** Network tab shows `/top.json` and `/badges.json` re-fetched every time the user returns to the homepage.

**Root cause:** `loadData()` runs in the constructor of `TavernBanner`. Glimmer components are re-instantiated on route entry.

**Fix:** Lift the cache to a module-level promise (the same pattern `honored-patrons.js` already uses with `patronsPromise`). Add a TTL (e.g., `Date.now() - lastFetch > 5 * 60 * 1000` to refetch). Alternatively, register a small Ember service for shared state.

**Phase:** 3.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **Phase 1: Banner duplication** | Both `head_tag.html` AND a connector mount the banner | Verify only one mount point; choose `discovery-list-container-top` over `below-site-header` |
| **Phase 1: "Pull a Stool" CTA** | Falling back to `<a href="/new-topic">` without a logged-in check | Use the composer service; redirect to `/login` if no current user |
| **Phase 1: Honored Patrons sidebar** | Tempting to keep `appEvents.trigger("sidebar:refresh")` because "it sometimes works" | Replace with `@tracked patrons = []`; the autotracking is the documented reactivity path |
| **Phase 1: Custom header** | Trying to `modifyClass` Discourse's header component to add nav links | Use `api.headerIcons.add(...)` for icons and CSS for the title/tagline; do NOT `modifyClass` the header |
| **Phase 2: SCSS overrides** | Layout changes on `.d-header` / `.sidebar-wrapper` break responsive behavior | Restrict overrides to color/typography; never change `display`, `flex-direction`, `position` on Discourse internals |
| **Phase 2: Stats panel live data** | Trying to fetch `/admin/dashboard.json` for active-user count (requires admin) | Use only the public endpoints (`/about.json`, `/site.json`, `/directory_items.json`) — verify each returns the field you need before depending on it |
| **Phase 3: I18n migration** | Translating only the obvious strings; missing settings descriptions | Audit `locales/en.yml` against every `{{this.settings.X}}` and `{{i18n}}` reference; the YAML is the source of truth |
| **All phases: Discourse upgrade** | Visual regressions ship silently because no tests exist | Manual visual smoke checklist on a staging Discourse before promoting; document the version each selector was last verified on |

---

## Cross-Cutting Watchpoints

**Glimmer component re-render rules.** The Discourse 3.x rendering model relies on `@tracked` fields and getters. Two of the most common causes of "component renders twice or in an unexpected position" specific to Discourse themes:

1. **Mounting the same component via two outlets.** A `connectors/below-site-header/banner.hbs` AND an `api.renderInOutlet("below-site-header", TavernBanner)` will both fire. The legacy file-based connector and the imperative API are independent registration paths.
2. **Mutating a non-tracked array.** Pushing to `this._patrons` (no `@tracked`) does not trigger a re-render; `this.patrons = newArray` (with `@tracked`) does. The "force a re-render via app event" pattern is a code smell that almost always points back to a missing `@tracked`.

**`api.container.lookup("service:app-events")` is fine, but only as a *listener*.** Triggering Discourse-internal events from a theme is risky because (a) the event may not exist, (b) the event signature can change between versions, (c) the same user-visible outcome is almost always achievable through tracked state. The current `honored-patrons.js` is *both* a listener (no) and a trigger (yes) — drop the trigger half.

**`headerIcons.add` / `headerIcons.delete` is the only stable API for nav-style buttons in the header.** Do not try to `modifyClass` the header component or inject children via `below-site-header` to fake header navigation. The "Trending / Rooms / Latest at the Bar / Top Shelf" links should be a sub-navigation strip *below* the header (in the banner area), not inside `.d-header`. If they truly must live inside the header, register each as a header icon via `api.headerIcons.add(...)`.

---

## Sources

- Context7 / `/discourse/discourse-developer-docs` — `/docs/03-code-internals/22-app-events-triggers.md` (composer:open, REFRESH_USER_SIDEBAR_CATEGORIES_SECTION_COUNTS)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/05-themes-components/03-designers-guide.md` (header styling, `.d-header`, `.d-icon`, `#main-outlet`)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/05-themes-components/14-localizable-strings.md` (`themePrefix`, `theme-i18n`)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/05-themes-components/25-homepage-content.md` (`above-main-container` example, route-scoped outlets)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/07-theme-developer-tutorial/04-outlets.md` (`api.renderInOutlet`, `discovery-list-container-top`, `@outletArgs`)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/07-theme-developer-tutorial/05-components.md` (`@tracked`, `@action`, Glimmer re-render rules)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/07-theme-developer-tutorial/06-js-api.md` (`api.headerIcons.add`)
- Context7 / `/discourse/discourse-developer-docs` — `/docs/03-code-internals/14-modifyclass.md` (modifyClass as last resort, brittleness warning)
- Context7 / `/discourse/discourse` — `/docs/developer-guides/docs/03-code-internals/22-app-events-triggers.md` (composer:open signature)
- Local codebase: `.planning/codebase/CONCERNS.md`, `.planning/codebase/CONVENTIONS.md`, `javascripts/discourse/api-initializers/honored-patrons.js`, `javascripts/discourse/components/tavern-banner.js`

**Sources NOT consulted (tooling unavailable in this run):**
- WebSearch (denied)
- WebFetch / Discourse Meta threads (denied)
- Discourse changelog / release notes — would have refined the 3.x → 3.2 → 3.4 selector-rename history. Confidence on the specific Glimmer header transition (Pitfall 4) is therefore MEDIUM rather than HIGH; recommend a Phase 1 follow-up to spot-check `.d-header` / `.sidebar-wrapper` against the running Discourse instance before relying on them.
