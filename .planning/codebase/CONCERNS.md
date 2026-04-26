# Codebase Concerns

**Analysis Date:** 2026-04-26

---

## Tech Debt

**Hardcoded strings bypass the i18n system:**
- Issue: The template `tavern-banner.hbs` hardcodes display strings ("Pull a stool", "Trending Tonight", "Project of the Night", "Recent Badges Awarded") directly in HTML rather than using `I18n.t(themePrefix(...))`. The locale file `locales/en.yml` defines keys for these strings (`liberty_tavern.banner.trending_now`, `liberty_tavern.banner.project_of_the_night`, etc.) that are never actually used in the template.
- Files: `javascripts/discourse/components/tavern-banner.hbs`, `locales/en.yml`
- Impact: The locale file is dead weight. Any copy changes must be made in two places (template and locale). Non-English translations are impossible without restructuring the template.
- Fix approach: Replace raw strings in the template with `{{i18n (theme-prefix "liberty_tavern.banner.trending_now")}}` etc., matching the keys already defined in `locales/en.yml`.

**`accent_hue` setting is defined but never consumed:**
- Issue: `settings.yml` declares `accent_hue` (integer, 0–360) with a description about driving "brass highlights," but no CSS in `common/common.scss` references this setting. All accent colors are hardcoded hex values (`#c8941a`, `#7a1f1f`, etc.).
- Files: `settings.yml`, `common/common.scss`
- Impact: Admins who adjust `accent_hue` see no effect. The setting is misleading and adds noise to the settings panel.
- Fix approach: Either remove the setting, or wire it up via a CSS custom property: `:root { --tavern-brass-hsl: hsl(settings.accent_hue, 68%, 45%); }` and replace hardcoded brass values with this variable.

**`about.json` contains placeholder GitHub URLs:**
- Issue: `about_url` and `license_url` in `about.json` both point to `https://github.com/your-org/liberty-tavern-theme`, which is a template placeholder, not an actual repository.
- Files: `about.json`
- Impact: Clicking "About this theme" in the Discourse admin panel navigates to a 404. Breaks standard Discourse theme metadata conventions.
- Fix approach: Update both URLs to the real GitHub repository once one is created, or remove the keys if the repo will remain private.

**README documents `/user-badges.json` but code uses `/badges.json`:**
- Issue: The README states "Component fetches `/user-badges.json`" but `tavern-banner.js` actually calls `/badges.json`. The two endpoints return different shapes (badge definitions vs. per-user grants).
- Files: `javascripts/discourse/components/tavern-banner.js` (line 64), `README.md`
- Impact: The "Recent Badges Awarded" card shows badge definitions sorted by total grant count rather than recently awarded grants. The feature behaves as a popularity list, not a live activity feed, which contradicts the stated intent.
- Fix approach: Either (a) accept the current behavior and update the README and heading copy to say "Most Awarded Badges," or (b) implement a proper recent-grants query using `/user_badges.json?limit=20` (no username) if that endpoint supports it, or paginate `/badge_grants.json`.

**Inline styles in Handlebars template:**
- Issue: Two `style="..."` attributes are hardcoded directly in `tavern-banner.hbs` (on the `<a>` wrapper of the featured topic and the `<h3>` inside it).
- Files: `javascripts/discourse/components/tavern-banner.hbs` (lines 34–36)
- Impact: The inline styles cannot be overridden by child themes or user stylesheets without `!important`. They also duplicate CSS that already exists in `common.scss`.
- Fix approach: Remove both inline style attributes and handle the styles via the existing `tavern-banner.hbs` SCSS block in `common/common.scss`.

---

## Known Bugs

**Banner visibility CSS selector conflict:**
- Symptoms: The banner body-class selector at the bottom of `common/common.scss` includes `body.archetype-regular .tavern-banner { display: none; }` immediately after a rule that has already listed `body:not(.navigation-topics):not(.navigation-categories):not(.archetype-regular)`. The `.archetype-regular` class is both excluded from the first selector and then explicitly hidden by the second. This is correct in isolation, but the intent is unclear—if a route gains `.archetype-regular` and `.navigation-topics` simultaneously, the banner would show even though the developer intended it hidden on topic pages.
- Files: `common/common.scss` (lines 392–393)
- Trigger: Opening any single topic page (`archetype-regular` class) — banner is hidden correctly today, but the logic is redundant and fragile.
- Workaround: None needed currently; the behavior is correct but accidentally so.

**`/new-topic` CTA link is not a Discourse route:**
- Symptoms: The "Pull a stool" CTA button in the banner links to `/new-topic`. Discourse's new-topic flow is triggered via `#` hash or the compose button, not a URL path. Navigating to `/new-topic` returns a 404.
- Files: `javascripts/discourse/components/tavern-banner.hbs` (line 7)
- Trigger: Any user clicks "Pull a stool."
- Workaround: None. The link silently 404s.
- Fix approach: Replace with a JavaScript action that calls `this.composer.open(...)` via the Discourse composer service, or simply link to `/latest` with a note.

**`sidebar:refresh` event trigger may silently no-op:**
- Symptoms: After patrons load, `honored-patrons.js` calls `appEvents.trigger("sidebar:refresh")`. This is not a documented Discourse app-event. The sidebar renders correctly on first render only because `_patrons` starts empty. If the sidebar has already fully rendered before the AJAX call resolves, the section will show zero links and never update.
- Files: `javascripts/discourse/api-initializers/honored-patrons.js` (lines 55–58)
- Trigger: Slow connections or a cold-cache API response.
- Workaround: None visible to the user — the section just shows empty.
- Fix approach: Use `@tracked` with a Glimmer component approach instead of the imperative `api.addSidebarSection` pattern, so that the tracked array drives reactivity automatically.

---

## Security Considerations

**No input sanitization on settings strings rendered into the DOM:**
- Risk: `banner_title` and `banner_subtitle` are theme settings of type `string` rendered via `{{this.settings.banner_title}}` in the Handlebars template. Discourse theme settings are admin-only, so injection requires admin access — low risk in practice. However, if these settings are ever surfaced in a multi-tenant or user-editable context, the lack of explicit escaping is a concern.
- Files: `javascripts/discourse/components/tavern-banner.hbs` (lines 5–6), `settings.yml`
- Current mitigation: Glimmer's `{{...}}` double-curly syntax HTML-escapes by default. No raw `{{{...}}}` triple-curly is used.
- Recommendations: No immediate action required. Do not switch to `{{{...}}}` for these fields without sanitization.

**External font load from Google Fonts:**
- Risk: `common/head_tag.html` loads fonts from `fonts.googleapis.com` and `fonts.gstatic.com`. This creates a third-party network dependency and sends the user's IP to Google on every page load.
- Files: `common/head_tag.html`, `common/common.scss` (line 9)
- Current mitigation: None.
- Recommendations: For privacy-sensitive deployments, self-host the fonts or use a `font-display: optional` fallback strategy. The `@import` in `common.scss` is a duplicate of the `<link>` in `head_tag.html` — remove the `@import` to avoid a double request.

---

## Performance Bottlenecks

**Double font load (duplicate requests):**
- Problem: Google Fonts are loaded twice — once via `<link>` in `common/head_tag.html` and again via `@import url(...)` at the top of `common/common.scss`. Both requests resolve the same CSS file.
- Files: `common/head_tag.html`, `common/common.scss` (line 9)
- Cause: Two independent load mechanisms for the same resource were added without deduplication.
- Improvement path: Remove the `@import` line from `common/common.scss`. The `<link>` preconnect + stylesheet in `head_tag.html` is the faster path (parser-blocking vs. CSS-blocking).

**Sequential AJAX calls in banner load:**
- Problem: `tavern-banner.js` `loadData()` is fully sequential — `/top.json` must complete before `/latest.json` fallback, which must complete before `/badges.json`. On slow connections this chains three round trips.
- Files: `javascripts/discourse/components/tavern-banner.js` (lines 37–83)
- Cause: `await` chain with conditional fallback logic makes parallelization non-trivial but not impossible.
- Improvement path: Fire `/top.json` and `/badges.json` in parallel with `Promise.all`. Only trigger `/latest.json` as a conditional fallback after `/top.json` resolves if the topic count is insufficient.

**No caching for badge or trending data:**
- Problem: `loadData()` fires fresh AJAX calls on every component mount. The `honored-patrons.js` caches via `patronsPromise` (module-level variable), but the banner component has no equivalent cache. Every homepage navigation triggers up to three API calls.
- Files: `javascripts/discourse/components/tavern-banner.js`
- Cause: No session storage, service-level caching, or TTL strategy implemented.
- Improvement path: Store fetched data in a lightweight Ember service with a short TTL (e.g., 5 minutes), shared across component mounts.

---

## Fragile Areas

**CSS class-name coupling to Discourse internals:**
- Files: `common/common.scss`
- Why fragile: The entire stylesheet targets Discourse-internal class names (`.d-header`, `.sidebar-wrapper`, `.sidebar-section-link`, `.search-menu`, `.topic-list`, `.badge-category__wrapper`, `.d-header-icons`, etc.). Discourse core renames or restructures these selectors periodically between major versions.
- Safe modification: Before upgrading Discourse, audit the changelog for CSS class renames. Add a brief comment per section listing the Discourse version where the selector was last verified.
- Test coverage: None. No visual regression tests exist.

**`shouldShow` route detection relies on route name prefix:**
- Files: `javascripts/discourse/components/tavern-banner.js` (line 29)
- Why fragile: The banner shows only when `router.currentRouteName` matches `/^discovery\./`. If Discourse renames any discovery route (e.g., to `discovery-latest` or `home.latest`) the banner silently disappears on all pages.
- Safe modification: After any Discourse upgrade, verify the banner still appears on the homepage by checking the current route name in the browser console.
- Test coverage: None.

**`sidebar:refresh` is an undocumented event:**
- Files: `javascripts/discourse/api-initializers/honored-patrons.js` (line 57)
- Why fragile: There is no guarantee `sidebar:refresh` will continue to trigger a re-render across Discourse versions. If this event name changes or is removed, the patrons section permanently shows empty on page loads where the AJAX response arrives after initial render.
- Safe modification: Monitor Discourse changelogs for sidebar API changes. Consider migrating to a tracked Glimmer component approach when the API stabilizes.

---

## Test Coverage Gaps

**No tests of any kind:**
- What's not tested: All JavaScript logic — `loadData()` error handling, `shouldShow()` route detection, `patronsPromise` caching, badge tier mapping, topic URL construction, `categoryBadge()` fallback.
- Files: `javascripts/discourse/components/tavern-banner.js`, `javascripts/discourse/api-initializers/honored-patrons.js`
- Risk: Any silent regression in API shape (e.g., Discourse changing `topic_list.topics` to a different key) or route naming will not be caught until visible in production.
- Priority: High for `tavern-banner.js` `loadData()` (most complex logic); Medium for `honored-patrons.js`.

**No visual regression tests:**
- What's not tested: Banner layout at various viewport widths, dark mode color scheme rendering, sidebar patron section display.
- Files: `common/common.scss`
- Risk: CSS changes silently break layout on mobile or in the dark color scheme.
- Priority: Medium.

---

*Concerns audit: 2026-04-26*
