---
phase: 02-custom-header
verified: 2026-04-27T00:00:00Z
status: human_needed
score: 7/8 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Logo image, title, and tagline visible on every page"
    expected: "Every page (homepage, /latest, /categories, a topic page, a profile page) shows the logo.png image, 'The Liberty Tavern' title, and 'Free Speech · Est. MDCCXCI' tagline in the header"
    why_human: "Requires a live browser — Discourse must upload/enable the theme and serve assets via theme-asset helper; cannot verify CDN URL resolution or actual render from grep"
  - test: "Sign In button displays and opens login modal (logged-out)"
    expected: "In an incognito browser window, the header shows a brass-colored 'Sign In' button (not 'Log In'); clicking it opens the Discourse login modal without navigating away"
    why_human: "Auth flow and modal open behavior require a live browser session; button label comes from a client-side i18n patch that only runs after Discourse JS boots"
  - test: "Nav pills show correct tavern labels after top_menu admin step"
    expected: "After setting top_menu to 'hot|latest|categories|top' in Admin → Settings, the header nav shows four pills: Trending, Rooms, Latest at the Bar, Top Shelf — each routing to /hot, /categories, /latest, /top respectively"
    why_human: "Pill rendering depends on the Discourse top_menu site setting (a live admin action) and client-side i18n.translations mutation that runs at browser boot; no offline simulation is possible"
  - test: "Native search icon and user-menu remain functional"
    expected: "Clicking the search icon opens the search overlay; clicking the user avatar (when logged in) opens the user menu; neither is hidden or broken by the custom SCSS"
    why_human: "Requires live browser interaction to confirm click events work and that no CSS z-index or overflow rule introduced by the theme hides these native icons"
  - test: "Page content does not overlap the header"
    expected: "On every page, content begins below the 64px header bar; no topic titles or banner text are hidden behind the header; no visual jump/reflow after page load"
    why_human: "Requires visual inspection across multiple routes; padding-top compensation is in SCSS but actual computed layout depends on Discourse's own padding/margin stack which can vary by route"
---

# Phase 2: Custom Header — Verification Report

**Phase Goal:** Replace Discourse's default header chrome with the tavern header bar shown in Image 1, while preserving native search and user-menu functionality.
**Verified:** 2026-04-27
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every page shows the tavern logo image in the header | ✓ VERIFIED | `tavern-logo.hbs` uses `{{theme-asset "logo.png"}}` at the `home-logo-contents` outlet path; `assets/logo.png` confirmed present |
| 2 | "The Liberty Tavern" and "Free Speech · Est. MDCCXCI" appear beside the logo | ✓ VERIFIED | Both strings present verbatim in `tavern-logo.hbs` lines 10–11; tagline uses correct U+00B7 middle dot |
| 3 | Logged-out visitors see a brass-colored Sign In button in the header | ✓ VERIFIED (code) / ? HUMAN | `.login-button` SCSS block exists with `background: var(--tavern-brass)`, `color: #1a120c`, `text-transform: uppercase`; label "Sign In" patched via `translations.js.log_in = "Sign In"` in `theme-setup.js` line 41 — visual confirmation requires browser |
| 4 | Native search icon and user-menu icon are visible, correctly colored, and open on click | ✓ VERIFIED (code) / ? HUMAN | No `display`, `flex-direction`, or `position` properties added to `.d-header` directly; existing `.nav-item-link, .icon, .d-header-icons .icon` color rules untouched — functional test requires browser |
| 5 | Header is 64px tall; page content does not overlap or jump under the header | ✓ VERIFIED (code) / ? HUMAN | `min-height: 64px` at `common.scss:73`; `#main-outlet-wrapper, #main-outlet { padding-top: 64px }` at `common.scss:150–153` — layout confirmation requires browser |
| 6 | Nav pills show: Trending, Rooms, Latest at the Bar, Top Shelf | ✓ VERIFIED (code) / ? HUMAN | `theme-setup.js` patches all four keys: `filters.hot.title = "Trending"` (line 33), `filters.categories.title = "Rooms"` (line 36), `filters.latest.title = {zero/one/other: "Latest at the Bar..."}` (lines 23–27), `filters.top.title = "Top Shelf"` (line 30) — requires `top_menu` admin step and browser to confirm render |
| 7 | Sign In button label reads "Sign In" (not "Log In") | ✓ VERIFIED | `translations.js.log_in = "Sign In"` guarded by `if (translations.js.log_in !== undefined)` at `theme-setup.js:40–41` |
| 8 | top_menu admin step is documented | ✓ VERIFIED | Fully documented in `02-02-PLAN.md` frontmatter `user_setup` block (lines 29–38): location, exact value `hot|latest|categories|top`, timing note |

**Score:** 7/8 truths verified via code (truth #6 is a conditional dependency on an admin action — the code implementation is complete; the admin step is documented); 5 truths additionally require live browser confirmation.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `javascripts/discourse/connectors/home-logo-contents/tavern-logo.hbs` | Logo connector replacing default Discourse logo area | ✓ VERIFIED | 13 lines; all BEM classes present; no inline style=; no JS companion file |
| `common/common.scss` — `.d-header` extensions | min-height, login-button, nav pills states | ✓ VERIFIED | All required blocks present at lines 73–105 |
| `common/common.scss` — `.tavern-logo` BEM classes | Logo layout rules | ✓ VERIFIED | All six BEM selectors present at lines 110–153 |
| `common/common.scss` — `#main-outlet-wrapper` padding | 64px content offset | ✓ VERIFIED | Lines 150–153 |
| `javascripts/discourse/api-initializers/theme-setup.js` | i18n patch for nav labels and Sign In | ✓ VERIFIED | All four filter keys patched; `log_in` patched; Phase 1 banner wiring preserved |
| `assets/logo.png` | Logo image referenced by theme-asset helper | ✓ VERIFIED | File confirmed present in `assets/` directory |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `tavern-logo.hbs` | `home-logo-contents` Discourse outlet | Connector file path `connectors/home-logo-contents/tavern-logo.hbs` | ✓ WIRED | Correct path convention — Discourse auto-discovers connectors by directory name matching outlet name |
| `common.scss .d-header .login-button` | `.login-button` rendered by `auth-buttons.gjs` | SCSS class targeting | ✓ WIRED | `.login-button` is the class Discourse's `auth-buttons.gjs` applies; SCSS block confirmed at line 75 |
| `theme-setup.js` | Discourse i18n translations store | `import { i18n } from "discourse-i18n"` + `i18n.translations[locale].js` mutation | ✓ WIRED | Import at line 2; mutations guarded by `translations?.js` null check at line 18 |
| `theme-setup.js` | Phase 1 banner (TavernBanner) | `api.renderInOutlet("discovery-list-container-top", TavernBanner)` | ✓ WIRED | Line 8; Phase 1 wiring preserved and guarded by `show_homepage_banner` setting |

### Data-Flow Trace (Level 4)

This phase delivers static markup (HBS connector) and client-side string patches (i18n mutation). No dynamic data flows from a database or API in Phase 2 — logo.png is a static asset, nav labels are hardcoded strings, and the Sign In button is a Discourse-native element. Level 4 data-flow trace is not applicable.

### Behavioral Spot-Checks

Step 7b: SKIPPED — this is a Discourse theme with no runnable entry points outside a live Discourse instance. All code is loaded and executed by the Discourse forum server/client. Static file checks substituted above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| HEAD-01 | 02-01-PLAN.md | Custom header displays Liberty Tavern logo on every page | ✓ SATISFIED | `tavern-logo.hbs` at `home-logo-contents` outlet fires on all Discourse routes; `assets/logo.png` present |
| HEAD-02 | 02-01-PLAN.md | Header displays "The Liberty Tavern" title and "Free Speech · Est. MDCCXCI" tagline | ✓ SATISFIED | Both strings verbatim in `tavern-logo.hbs` lines 10–11 |
| HEAD-03 | 02-02-PLAN.md | Header displays nav links: Trending, Rooms, Latest at the Bar, Top Shelf | ✓ SATISFIED (code complete; admin step required) | All four i18n keys patched in `theme-setup.js`; `top_menu` admin step documented in plan `user_setup` frontmatter |
| HEAD-04 | 02-01-PLAN.md, 02-02-PLAN.md | Header displays Sign In button for anonymous users (styling + correct label) | ✓ SATISFIED | `.login-button` brass styling in `common.scss:75–88`; `translations.js.log_in = "Sign In"` in `theme-setup.js:41` |
| HEAD-05 | 02-01-PLAN.md | Discourse's native search and user-menu remain functional | ✓ SATISFIED (code) / ? HUMAN | No layout-breaking properties (`display`, `flex-direction`, `position`) added to `.d-header`; native icon color rules retained from Phase 1 — functional confirmation requires browser |

All five HEAD requirements are accounted for. No orphaned requirements identified. REQUIREMENTS.md maps HEAD-01 through HEAD-05 exclusively to Phase 2 — all five are claimed by plans in this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `common/common.scss` | 73 | `min-height: 64px` placed after the `.btn-primary` block but still inside `.d-header {}` — minor style ordering concern | ℹ️ Info | None — SCSS specificity unaffected; `.d-header` closing brace is at line 106 |

No TODOs, FIXMEs, placeholder text, or return-null stubs found in any of the three Phase 2 files. `locales/en.yml` does not override `js.*` core strings (only `theme_metadata` and `liberty_tavern.*` namespace keys are present — correct). No `@import` added. No inline `style=` attributes in HBS.

The `filters.latest.title` is correctly assigned as a pluralized object (`{zero, one, other}`) rather than a plain string — the critical pitfall documented in the research is handled correctly.

### Human Verification Required

The following items require a live Discourse browser session to confirm. The code implementation is complete for all items — these are render/interaction checks only.

#### 1. Logo, Title, and Tagline Visible on Every Page

**Test:** With the theme enabled, open four pages: homepage (`/`), a topic, `/categories`, and a user profile. Compare the header logo area against Image 1.
**Expected:** Logo image renders (not broken image), "The Liberty Tavern" title appears in Playfair italic, "Free Speech · Est. MDCCXCI" tagline appears in small uppercase Inter below it — on all four pages.
**Why human:** Requires Discourse instance with theme uploaded and `assets/logo.png` served via the CDN-resolved `theme-asset` URL.

#### 2. Sign In Button — Appearance and Behavior

**Test:** Open the forum in an incognito/private window. Inspect the header.
**Expected:** A brass-colored button labeled "Sign In" (not "Log In") appears in the header. Clicking it opens the Discourse login modal without a page navigation.
**Why human:** The i18n patch runs client-side after Discourse JS boots. The `auth-buttons.gjs` component must be present and the `log_in` translation key must exist at runtime for the patch to apply.

#### 3. Nav Pills — Four Correct Labels After Admin Step

**Pre-condition:** Admin must first set `top_menu` to `hot|latest|categories|top` in Admin → Settings.
**Test:** After saving the `top_menu` setting and refreshing the forum, inspect the nav pill row in the header.
**Expected:** Four pills appear: **Trending**, **Rooms**, **Latest at the Bar**, **Top Shelf**. Clicking Trending routes to `/hot`, Rooms to `/categories`, Latest at the Bar to `/latest`, Top Shelf to `/top`. No `[missing "en.filters.latest.title" translation]` console errors.
**Why human:** Nav pill rendering is driven by `top_menu` (a site setting, not theme-controllable) plus the client-side i18n patch. Both must be active simultaneously.

#### 4. Native Search and User Menu Still Work

**Test:** Click the magnifying glass search icon. Then (when logged in) click the user avatar.
**Expected:** Search overlay opens on search icon click. User menu opens on avatar click. Both icons are visible and correctly colored (cream `#f5ebd9` with brass hover), not hidden or clipped.
**Why human:** Requires interactive browser click events; CSS z-index and overflow interactions with native Discourse components cannot be confirmed by static analysis.

#### 5. No Content-Header Overlap

**Test:** On the homepage and a topic page, scroll to the top and inspect whether any content is hidden behind the 64px header bar.
**Expected:** Page content begins below the header. No topic titles, banner elements, or other content are obscured. No scroll-jump on initial load.
**Why human:** Computed layout depends on Discourse's own padding/margin stack per route. The SCSS compensation (`padding-top: 64px` on `#main-outlet-wrapper` and `#main-outlet`) is in place but may interact with route-specific overrides Discourse applies.

---

## Summary

Phase 2 code is complete and clean. All three implementation files are substantive and wired:

- `tavern-logo.hbs` correctly implements the `home-logo-contents` WRAPPER outlet replacement with BEM markup, no inline styles, and proper `@outletArgs.title` alt text.
- `common.scss` adds the full logo BEM ruleset, `.login-button` brass styling with focus/active states, nav pill active/focus styles, `min-height: 64px`, and the `padding-top: 64px` content offset — none of which violate the CLAUDE.md constraint against layout properties on `.d-header`.
- `theme-setup.js` adds the i18n patch using the correct mechanism (JS mutation, not `locales/en.yml`), correctly handles the pluralized `filters.latest.title` key as an object, and preserves Phase 1 banner wiring.

The one conditional item (HEAD-03 / nav pills) correctly documents the required one-time admin step (`top_menu` site setting) which cannot be automated via theme code — this is an architectural constraint of Discourse, not a gap in the implementation.

Five human verification items exist because this is a Discourse theme: there is no automated test runner and all render/interaction behavior can only be confirmed in a live browser. The automated checks pass fully.

All commits (ffec477, bab509b, 40b9bf0) are confirmed present in git history.

---
_Verified: 2026-04-27_
_Verifier: Claude (gsd-verifier)_
