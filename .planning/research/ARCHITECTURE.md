# Architecture Patterns — Discourse Theme

**Domain:** Discourse theme (brownfield)
**Researched:** 2026-04-26
**Confidence:** HIGH (Context7 / Discourse developer docs are primary sources)

---

## TL;DR — Recommended Architecture

| Concern | Current (broken) | Recommended |
|---|---|---|
| Banner mount point | Connector at `below-site-header` (whole-page outlet, fires on every route) | API initializer + `api.renderInOutlet("discovery-list-container-top", ...)` (homepage-scoped) — OR connector at `above-main-container` |
| Custom header | Absent (previous attempts reverted) | API initializer + `home-logo-contents` **wrapper outlet** (replaces logo) **+** `api.headerIcons.add(...)` for nav buttons; do **not** rebuild the entire `<header>` |
| Right-column layout | None | Connector at `after-main-outlet` + CSS grid override on `#main-outlet-wrapper` (Redditish-theme pattern) |
| Sidebar reactivity | `appEvents.trigger("sidebar:refresh")` (undocumented) | Module-level `@tracked` array referenced by the section's `links` getter — autotracking re-renders without manual events |

---

## 1. Banner duplication — root cause and fix

### What the current code does
- `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` mounts `<TavernBanner />`
- `below-site-header` is a **whole-page outlet** that fires on every route — discovery, topic, user, admin, search, etc.
- The component self-suppresses via `shouldShow` (matches `/^discovery\./`) — so on non-homepage routes it returns nothing
- `common/after_header.html` is currently just a comment (no leftover HTML)

### Likely cause of the duplicate
Two architectural causes are consistent with the symptom (one unstyled instance at the top, one styled instance lower down):

**Cause A (most likely): `below-site-header` is the wrong outlet for homepage content.**
- The `below-site-header` outlet renders **outside** the homepage discovery layout, above `#main-outlet-wrapper`. On the homepage, Discourse already paints its native homepage banner / "Welcome back" content **inside** the discovery template tree. The result is two visually distinct regions on the homepage: your `<TavernBanner />` sitting above the layout (unstyled because the surrounding `#main-outlet` SCSS context is missing), and Discourse's own banner area below it.
- The `.tavern-banner` SCSS in `common/common.scss` was authored assuming the banner sits inside `#main-outlet` (margin/grid alignment, max-width) — placing it above the wrapper produces an "unstyled-looking" render even though the rules technically apply.

**Cause B (secondary): connector + initializer double-mount.**
- If at any point a parallel `api.renderInOutlet(...)` or a second connector file is added (e.g. while migrating), Discourse will mount both. Discourse does not deduplicate component mounts across connector files and `renderInOutlet` calls.

### Recommended fix
Use **`discovery-list-container-top`** (homepage-scoped, official) **or** **`above-main-container`** (homepage + categories + tags):

```javascript
// javascripts/discourse/api-initializers/tavern-banner.gjs
import { apiInitializer } from "discourse/lib/api";
import TavernBanner from "../components/tavern-banner";

export default apiInitializer("1.13.0", (api) => {
  if (!settings.show_homepage_banner) return;
  api.renderInOutlet("discovery-list-container-top", TavernBanner);
});
```

Then **delete** `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` so there is exactly one mount point. The component's existing `shouldShow` getter becomes redundant for the route check (Discourse only renders the outlet on discovery routes) but remains valid as a settings guard.

**Why `discovery-list-container-top` over `above-main-container`:**
| Outlet | Fires on | Pros | Cons |
|---|---|---|---|
| `discovery-list-container-top` | Homepage + category/tag list pages | Tight to homepage; positioned **inside** the topic-list container so SCSS context is correct | Will also render on category pages (use `defaultHomepage()` check inside the component if you want strict homepage-only) |
| `above-main-container` | Homepage + categories + tags + most discovery views | Simple, broadly used (this is what `discourse-homepage-feature-component` uses for one of its modes) | Renders outside `#main-outlet`; needs explicit width/margin SCSS |
| `below-site-header` | **Every route in the app** | Useful for site-wide announcements only | Wrong scope for homepage-only content; positioned outside the layout grid |

**Strict-homepage detection** (matches Discourse docs pattern):
```javascript
import { defaultHomepage } from "discourse/lib/utilities";
// inside the component
get isHomepage() {
  return this.router.currentRouteName === `discovery.${defaultHomepage()}`;
}
```
This is more robust than the current `/^discovery\./.test(route)` regex, which fires on `/categories`, `/tags`, etc.

---

## 2. Custom header architecture

### What NOT to do
- **Do not** rebuild the entire `<header>` via `common/after_header.html` HTML injection. That HTML lands AFTER Discourse's own header element and cannot replace it; it produces stacked/double headers.
- **Do not** replace `site-header` wholesale. There is no public site-header wrapper outlet, and overriding it cuts you off from Discourse's hamburger, search, user-menu, and accessibility wiring.
- **Do not** target `header-contents` — it is not a stable, documented public outlet name in current Discourse.
- The git history of `721a715` → `dc931a8` (custom-header → reverted) confirms full-header replacement is the wrong path.

### What TO do — three composable surface areas

Discourse exposes the header in three official ways. **Combine them**, do not replace.

**A. `home-logo-contents` — wrapper outlet (replaces the logo only)**

This is documented in the Discourse developer docs as a wrapper outlet. Replacing the logo with a logo + tagline block is the correct way to add the "Liberty Tavern" + tagline you see in the design target, **next to** Discourse's existing nav.

```javascript
// javascripts/discourse/api-initializers/tavern-logo.gjs
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.13.0", (api) => {
  api.renderInOutlet("home-logo-contents", <template>
    <a href="/" class="tavern-logo">
      <img src={{settings.tavern_logo_url}} alt="Liberty Tavern" />
      <span class="tavern-logo__title">The Liberty Tavern</span>
      <span class="tavern-logo__tagline">{{settings.tavern_tagline}}</span>
    </a>
  </template>);
});
```

Wrapper outlets **replace** the wrapped core content. If you want to keep the default logo image and add to it, use `{{yield}}` inside the template.

**B. `api.headerIcons.add(...)` — for the nav links (Trending, Rooms, Latest at the Bar, Top Shelf)**

These are not "icons" only — they can be `<DButton>` or any `<li>` content. Discourse positions them in the existing `.d-header-icons` list, so they line up with the search/user icons automatically.

```javascript
import DButton from "discourse/components/d-button";
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.13.0", (api) => {
  api.headerIcons.add("tavern-trending", <template>
    <li>
      <DButton @route="discovery.top" @label="Trending" class="btn-flat tavern-nav-link" />
    </li>
  </template>, { before: "search" });

  api.headerIcons.add("tavern-rooms", <template>
    <li>
      <DButton @route="discovery.categories" @label="Rooms" class="btn-flat tavern-nav-link" />
    </li>
  </template>, { before: "search" });

  // ...etc
});
```

`{ before: "search" }` puts your buttons left of the search icon. Other anchor names: `"hamburger"`, `"user-menu"`. If you omit the option, they append to the end.

**C. `common/common.scss` — visual styling of `.d-header`**

Style the existing header box. The Discourse designers' guide explicitly documents this pattern: target `.d-header` for height/border/background, then bump `#main-outlet { padding-top }` to match.

```scss
.d-header {
  background: var(--tavern-cream);
  border-bottom: 2px solid var(--tavern-oxblood);
  height: 5em;
}
.tavern-nav-link { font-family: var(--font-display); }
#main-outlet { padding-top: 6.5em; } // when increasing header height
```

### Why this layered approach is correct
- Keeps Discourse's hamburger, search, user menu, notifications, login button — all of which have non-trivial routing, accessibility, and mobile behavior wired up
- Gives you 100% of the visual customization power needed for the design target
- Survives Discourse upgrades because every surface used (`home-logo-contents`, `headerIcons.add`, `.d-header` SCSS) is officially documented
- No conflict with Discourse's own header JS — you are augmenting, not replacing

---

## 3. Homepage layout structure (banner → trending → rooms → right column)

### The right-column problem
Discourse's default homepage layout is **single-column** (sidebar + main outlet). There is no built-in two-column layout for the discovery page, so you cannot inject a "right column" via outlets alone — you need a layout override.

### Recommended structure (proven by the Redditish theme)

The Redditish theme (`/discourse/discourse-redditish-theme`) solves exactly this problem with the following pattern, which I recommend adopting:

1. **Mount the right-column container in `after-main-outlet`** (a connector that renders a wrapper component for badges + house rules):
   ```handlebars
   <!-- javascripts/discourse/connectors/after-main-outlet/tavern-right-column.hbs -->
   <TavernRightColumn />
   ```
2. **Override `#main-outlet-wrapper` via CSS Grid** in `common/common.scss` to give it a six-column grid where the right column lives between the main content and the sidebar-spacer:
   ```scss
   body[class*="navigation-"]:not([class*="archetype-"]) {
     #main-outlet-wrapper {
       grid-template-areas:
         "sidebar lspace content rcol rspace sidebar-spacer";
       grid-template-columns:
         var(--d-sidebar-width) 1fr minmax(0, 720px)
         300px 1fr var(--d-sidebar-width);
       gap: 0 1.5em;
       @media screen and (max-width: 1160px) {
         .tavern-right-column { display: none; } // hide on narrow screens
       }
     }
   }
   ```
3. **Section-by-section outlet map:**

| Homepage section | Outlet / surface | Notes |
|---|---|---|
| Custom header (logo + nav) | `home-logo-contents` (wrapper) + `headerIcons.add` | See section 2 |
| Banner (hero + stats) | `discovery-list-container-top` | One mount, homepage-scoped |
| Trending strip (3-up) | Inside the banner component (already in the template) | No separate outlet needed |
| Rooms section (category cards) | `categories-only` template override **OR** style `.category-list` directly | Discourse already renders categories; restyle rather than re-render |
| Right column: Badges + House Rules | `after-main-outlet` connector + grid override | See above |
| Honored Patrons sidebar | `api.addSidebarSection` (existing, fix reactivity per §4) | Already correct outlet |

### Why this works
- `after-main-outlet` renders **inside** `#main-outlet-wrapper`, so it participates in the grid
- Grid template areas are the cleanest way to add a column to a layout that wasn't originally designed for it
- The Redditish theme is a maintained, official-org Discourse theme using exactly this pattern — high confidence it survives Discourse upgrades

### What WON'T work
- ~~Trying to inject a right column via `above-main-container`~~ — that outlet renders above the wrapper, not beside the content
- ~~Hacking the right column into the existing sidebar~~ — Discourse's sidebar is left-only and stateful (collapsible), reusing it for content cards confuses users
- ~~Using flexbox on `#main-outlet`~~ — Discourse's responsive logic assumes grid; flex breaks at narrow viewports

---

## 4. Honored Patrons sidebar reactivity

### Why the current code is fragile
1. `appEvents.trigger("sidebar:refresh")` is **not** in the documented Discourse AppEvents list. The documented sidebar event is `REFRESH_USER_SIDEBAR_CATEGORIES_SECTION_COUNTS_APP_EVENT_NAME`, which is for category counts only.
2. Even if `sidebar:refresh` happens to work today, it's an undocumented event that can be removed without notice.
3. Worse: the current code stores `_patrons` as a plain instance property (not `@tracked`), so even if the section instance re-evaluates `links`, Glimmer has no way to know the underlying array changed.

### Recommended pattern — module-scoped `@tracked` cell

The idiomatic Glimmer/Ember approach is **autotracking**: store `_patrons` in a tracked cell at module scope; the section's `links` getter reads from it; updating the cell automatically invalidates the getter and re-renders the sidebar. No imperative event triggers needed.

```javascript
// javascripts/discourse/api-initializers/honored-patrons.js
import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { TrackedArray } from "@ember-compat/tracked-built-ins";

export default apiInitializer("1.13.0", (api) => {
  if (!settings.honored_patrons_enabled) return;

  const groupName = settings.honored_patrons_group || "trust_level_4";
  const limit = settings.honored_patrons_count || 4;

  // Tracked cell — all section instances read from it; updates auto-rerender
  const patrons = new TrackedArray();
  let loaded = false;

  function loadPatrons() {
    if (loaded) return;
    loaded = true;
    ajax(`/groups/${groupName}/members.json?limit=${limit}&order=added_at&asc=false`)
      .then((r) => {
        patrons.splice(0, patrons.length, ...(r.members || []));
      })
      .catch(() => {/* silent — sidebar shows empty */});
  }

  api.addSidebarSection((BaseSection, BaseLink) => {
    class PatronLink extends BaseLink {
      constructor({ user }) { super(); this.user = user; }
      // ... same getters as before
    }

    return class extends BaseSection {
      constructor() {
        super(...arguments);
        loadPatrons(); // fire once per page load
      }
      get name() { return "honored-patrons"; }
      get title() { return I18n.t(themePrefix("liberty_tavern.sidebar.honored_patrons")); }
      get text() { return this.title; }
      get displaySection() { return true; }
      get hideSectionHeader() { return false; }
      get links() {
        // Reads from tracked array — autotracks the dependency
        return patrons.slice(0, limit).map((u) => new PatronLink({ user: u }));
      }
      get actions() { return []; }
      get actionsIcon() { return null; }
    };
  });
});
```

**Key differences:**
- `TrackedArray` from `@ember-compat/tracked-built-ins` (or `@tracked patrons = []` + reassignment) — Discourse ships this; available at runtime
- `splice(0, length, ...newItems)` mutates the tracked array, which fires Glimmer's autotracking
- No `appEvents` call needed — Glimmer recomputes `links` on next render tick automatically
- No promise cache variable needed — `loaded` flag is sufficient and idiomatic

**Fallback if `TrackedArray` is unavailable** (older Discourse): use a tracked class:
```javascript
import { tracked } from "@glimmer/tracking";
class PatronStore {
  @tracked patrons = [];
}
const store = new PatronStore();
// In the section: get links() { return store.patrons.slice(...).map(...) }
// On AJAX resolve: store.patrons = r.members || [];   <-- reassign, don't mutate
```
Reassigning a `@tracked` property is the most portable approach across Discourse versions.

---

## 5. Build/refactor order (which fix unblocks the others)

The four problems have a clear dependency order. Tackle in this sequence:

### Phase 1 — Fix the banner mount point (blocks everything visual)
**Why first:** The duplicate render is the most visible bug; fixing it confirms the new outlet pattern works before you build on top of it. It's also the smallest change.
1. Create `javascripts/discourse/api-initializers/tavern-banner.gjs` that calls `api.renderInOutlet("discovery-list-container-top", TavernBanner)`
2. Delete `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs`
3. Replace `shouldShow` regex with `defaultHomepage()` check
4. **Verify:** banner renders exactly once, in the topic-list area, on the homepage only

### Phase 2 — Custom header (independent of layout work)
**Why second:** Header changes are visually independent from the homepage layout grid; doing them next gets the design target's identity bar in place without entangling layout work.
1. Add `api.renderInOutlet("home-logo-contents", ...)` for logo + title + tagline
2. Add `api.headerIcons.add(...)` calls for each nav link
3. Add `.d-header` SCSS overrides
4. **Verify:** header looks like the design target on all routes (homepage, topic, user profile)

### Phase 3 — Right-column layout (depends on banner being placed correctly)
**Why third:** The grid override touches `#main-outlet-wrapper`, which contains the banner. Moving the banner first means the grid changes only need to account for one known component, not a moving target.
1. Add `connectors/after-main-outlet/tavern-right-column.hbs` mounting `<TavernRightColumn />`
2. Build `<TavernRightColumn />` component with `<BadgesPanel />` and `<HouseRulesPanel />`
3. Add `#main-outlet-wrapper` grid override in SCSS, scoped to homepage body classes
4. Add the `@media (max-width: 1160px) { display: none }` rule for narrow viewports
5. **Verify:** right column appears beside content on wide screens, hides cleanly below 1160px

### Phase 4 — Sidebar reactivity (independent, do last as polish)
**Why last:** It's the least visible bug (only manifests on slow connections), and it's self-contained — no other phase depends on it. Easiest to verify in isolation.
1. Refactor `honored-patrons.js` to use `TrackedArray` or `@tracked` reassignment
2. Remove `appEvents.trigger("sidebar:refresh")` call
3. **Verify:** throttle network in DevTools to "Slow 3G", reload — section should populate when AJAX resolves, not stay empty

---

## 6. Discourse version-specific warnings

| Discourse version | Note |
|---|---|
| **3.0+** | Required for `api.addSidebarSection` |
| **3.2+** | `api.headerIcons.add` stable; recommended floor |
| **3.3+** | `api.renderInOutlet` with inline `<template>` (.gjs) supported. If targeting older, use `connectors/<outlet>/<name>.hbs` instead |
| **Any** | `home-logo-contents` is documented as a wrapper outlet — only **one** active theme/plugin can contribute to it. If a child theme component also uses it, the last-loaded wins. Document this in your theme README |
| **Any** | `headerIcons.add` anchor names (`"search"`, `"hamburger"`, `"user-menu"`) are stable but not formally part of the public API. Verify after Discourse upgrades by checking the rendered `.d-header-icons` order |
| **Any** | The `discovery.X` route names are stable, but `defaultHomepage()` from `discourse/lib/utilities` is the safe way to compare — admins can change the default homepage to `categories`, `top`, or `latest` per-site |
| **Any** | `#main-outlet-wrapper` grid override is a CSS-only intervention — no Discourse JS depends on it. But Discourse occasionally tweaks the wrapper's children (adds/removes class names), so audit after major version upgrades |
| **3.4+ (caveat)** | The Discourse glimmer-header migration is in progress in core. Wrapper outlets `home-logo-contents` and `headerIcons.add` are the two surfaces being kept stable across the migration; raw widget overrides (legacy approach) are being removed. Sticking to documented APIs is essential |

---

## 7. Component file structure (recommended end state)

```
javascripts/discourse/
├── api-initializers/
│   ├── tavern-banner.gjs          # NEW: api.renderInOutlet for banner
│   ├── tavern-header.gjs          # NEW: home-logo-contents + headerIcons.add
│   └── honored-patrons.js         # REFACTOR: tracked array, no appEvents
├── components/
│   ├── tavern-banner.js           # KEEP (minor: drop regex, use defaultHomepage)
│   ├── tavern-banner.hbs          # KEEP (minor: remove inline styles per concerns audit)
│   ├── tavern-logo.gjs            # NEW: logo + title + tagline
│   ├── tavern-right-column.gjs    # NEW: wraps badges + house rules
│   ├── badges-panel.gjs           # NEW
│   └── house-rules-panel.gjs      # NEW
└── connectors/
    └── after-main-outlet/
        └── tavern-right-column.hbs  # NEW: <TavernRightColumn />

# DELETE:
# javascripts/discourse/connectors/below-site-header/tavern-banner.hbs
```

The choice of `.gjs` (template tag) over `.js + .hbs` is recommended for new files — it's the format the Discourse developer tutorial promotes for modern theme work, keeps logic and template colocated, and is what `api.renderInOutlet` examples use throughout the official docs. The existing `tavern-banner.js + tavern-banner.hbs` split is fine to leave as-is; new components should use `.gjs`.

---

## Sources

- Discourse Developer Docs — Plugin Outlets and Connectors: https://github.com/discourse/discourse-developer-docs/blob/main/docs/03-code-internals/13-plugin-outlet-connectors.md (HIGH — official, current)
- Discourse Developer Docs — Theme tutorial: Outlets: https://github.com/discourse/discourse-developer-docs/blob/main/docs/07-theme-developer-tutorial/04-outlets.md (HIGH)
- Discourse Developer Docs — Theme tutorial: JS API: https://github.com/discourse/discourse-developer-docs/blob/main/docs/07-theme-developer-tutorial/06-js-api.md (HIGH — `api.headerIcons.add`)
- Discourse Developer Docs — Homepage content: https://github.com/discourse/discourse-developer-docs/blob/main/docs/05-themes-components/25-homepage-content.md (HIGH — `above-main-container`, `defaultHomepage()`)
- Discourse Developer Docs — Designers' guide: https://github.com/discourse/discourse-developer-docs/blob/main/docs/05-themes-components/03-designers-guide.md (HIGH — `.d-header` styling, `#main-outlet` padding)
- Discourse Developer Docs — App events triggers: https://github.com/discourse/discourse-developer-docs/blob/main/docs/03-code-internals/22-app-events-triggers.md (HIGH — confirms `sidebar:refresh` is undocumented)
- discourse-redditish-theme (reference implementation for two-column homepage): https://github.com/discourse/discourse-redditish-theme — `after-main-outlet` connector + `#main-outlet-wrapper` grid override (HIGH — official-org maintained theme)
- discourse-homepage-feature-component (reference for outlet positioning options): https://github.com/discourse/discourse-homepage-feature-component — uses `above-main-container`, `below-discovery-categories`, `discovery-list-controls-above` (HIGH — official-org maintained component)

All sources retrieved via Context7 (`/discourse/discourse-developer-docs`, `/discourse/discourse-redditish-theme`, `/discourse/discourse-homepage-feature-component`). No findings rely on training data alone.

---

*Architecture research: 2026-04-26*
