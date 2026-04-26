# Phase 1: Foundation Repair — Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the 8 visible bugs blocking all other phases: banner duplication, 404 CTA, flaky sidebar reactivity, Google Fonts double-load, inline styles, and missing accent_hue wiring. No new features. The homepage banner must render once, correctly positioned, before Phase 2 builds on top.

</domain>

<decisions>
## Implementation Decisions

### Anonymous CTA Behavior
- **D-01:** When a logged-out user clicks "Pull a Stool", call `router.transitionTo("login")` — standard Discourse login route. No modal, no hidden button. User logs in and navigates back manually.

### Honored Patrons Sidebar Display
- **D-02:** Keep current display: patron name + trust-level tier suffix ("Leader", "Regular", etc.). Fix only the reactivity bug (`_patrons` → `@tracked patrons`). No changes to what data is shown.

### api-initializer Structure
- **D-03:** Create a new file `javascripts/discourse/api-initializers/theme-setup.js` for the banner mount (`api.renderInOutlet`). Do NOT fold into `honored-patrons.js`. This file will grow as Phases 2–4 add header and layout setup.

### Claude's Discretion
- `shouldShow` route check: switch from regex `/^discovery\./` to `defaultHomepage()` if that function is available in the Discourse API, otherwise keep regex. Claude decides based on Discourse version in use.
- SCSS class names for removed inline styles: Claude chooses names consistent with existing `.tavern-banner__*` BEM pattern.
- accent_hue wiring approach: SCSS variable interpolation (`:root { --tavern-brass: hsl(#{$accent_hue}, 68%, 45%); }`) vs. CSS custom property in head_tag.html. Claude decides based on what the SCSS compiler in Discourse supports.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Research & Requirements
- `.planning/research/SUMMARY.md` — full stack recommendations, outlet decisions, and top-5 pitfalls. The single most important reference for Phase 1.
- `.planning/REQUIREMENTS.md` — FOUND-01..08 requirements with acceptance criteria
- `.planning/ROADMAP.md` — Phase 1 goal and 4 success criteria

### Existing Code (files being modified)
- `javascripts/discourse/components/tavern-banner.js` — Glimmer component; `shouldShow` regex and `loadData` async fetch
- `javascripts/discourse/components/tavern-banner.hbs` — inline `style="..."` on lines 34–36; `/new-topic` `<a>` link on line 7
- `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` — connector file to DELETE (replaced by api-initializer mount)
- `javascripts/discourse/api-initializers/honored-patrons.js` — `appEvents.trigger("sidebar:refresh")` bug; `_patrons` non-tracked field
- `about.json` — needs `theme_site_settings` block added; no `enable_welcome_banner` currently
- `common/common.scss` — remove `@import` for Google Fonts; add accent_hue wiring; add SCSS classes for removed inline styles

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TavernBanner` Glimmer component: already functional; only outlet mount, CTA, and inline styles need changing
- `honored-patrons.js`: sidebar section structure is correct; only reactivity mechanism is broken
- `about.json` color_schemes: fully defined; just needs `theme_site_settings` added

### Established Patterns
- BEM class naming: `.tavern-banner__*` already in use — follow for new SCSS classes
- Glimmer `@tracked`: already used in `tavern-banner.js` (`@tracked trending`, `@tracked badges`, etc.) — same pattern for patrons fix
- `apiInitializer("1.13.0", (api) => {...})`: already used in `honored-patrons.js` — new `theme-setup.js` follows identical structure

### Integration Points
- `about.json` → `theme_site_settings` block controls `enable_welcome_banner` and `desktop_category_page_style` (used in Phase 3)
- `api.renderInOutlet("discovery-list-container-top", TavernBanner)` in `theme-setup.js` replaces the connector file mount
- `common/common.scss` receives: `@import` removal, new inline-style SCSS classes, accent_hue `--tavern-brass` variable

</code_context>

<specifics>
## Specific Ideas

- The connector file `connectors/below-site-header/tavern-banner.hbs` should be deleted (not just emptied) — it is the source of the outlet-scope bug.
- Research confirms both fixes are needed for banner duplication: (A) disable WelcomeBanner via `theme_site_settings` AND (B) move outlet to `discovery-list-container-top`. Apply both.
- `accent_hue` in `settings.yml` is typed as a hue integer (0–360). The CSS variable should use `hsl()` with fixed saturation/lightness from the brass color (`#c8941a` ≈ hsl(37, 68%, 45%)`).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-foundation-repair*
*Context gathered: 2026-04-26*
