---
phase: 01-foundation-repair
verified: 2026-04-26T00:00:00Z
status: human_needed
score: 10/10 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Load the homepage in a browser. Inspect the DOM for elements with class 'tavern-banner'."
    expected: "Exactly one .tavern-banner section element appears, positioned above the topic list. No second banner or welcome-banner element is present."
    why_human: "api.renderInOutlet wiring and WelcomeBanner suppression are code-only checks; actual DOM deduplication requires a live Discourse install."
  - test: "Log in as a test user. Click the 'Pull a Stool' button in the banner."
    expected: "The Discourse new-topic composer opens. No page navigation occurs. No 404."
    why_human: "composer.openNewTopic() is a Discourse service call; whether the composer actually opens requires a running Discourse instance."
  - test: "Log out. Click the 'Pull a Stool' button in the banner."
    expected: "Browser navigates to /login. No 404."
    why_human: "router.transitionTo('login') requires a live Ember routing context to verify the transition fires correctly."
  - test: "Open browser DevTools → Network tab. Load the homepage with cache disabled."
    expected: "Exactly one request each for Playfair Display, Spectral, and Inter from fonts.googleapis.com. No duplicate font requests."
    why_human: "Duplicate @import removal is verified in code, but actual HTTP deduplication requires observing live network requests."
  - test: "Throttle connection to Slow 3G in DevTools. Load homepage. Observe the 'Honored Patrons' sidebar section."
    expected: "Patron names/avatars appear after a delay, without requiring a page refresh. Section does not stay empty."
    why_human: "@tracked reactivity requires a live Glimmer rendering context; cannot simulate Glimmer's change-tracking statically."
  - test: "Admin → Customize → Themes → Liberty Tavern → Settings. Change the 'Accent Hue' slider value. Save. Reload the homepage."
    expected: "The brass accent color (banner CTA button, header border, pinned topic indicator) visibly shifts to the new hue."
    why_human: "SCSS variable interpolation via $accent_hue requires Discourse's theme SCSS compilation to exercise; cannot verify color output statically."
---

# Phase 1: Foundation Repair — Verification Report

**Phase Goal:** Eliminate the visible bugs blocking everything else — banner duplication, 404 CTA, flaky sidebar, font/styling debt — so the homepage banner renders correctly once and the codebase is stable enough to build on.
**Verified:** 2026-04-26
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Banner outlet connector file no longer exists | VERIFIED | `connectors/below-site-header/` directory does not exist; no `.hbs` files in any connector directory |
| 2 | theme-setup.js mounts TavernBanner via api.renderInOutlet at discovery-list-container-top | VERIFIED | Line 6: `api.renderInOutlet("discovery-list-container-top", TavernBanner)` present and guarded by `settings.show_homepage_banner` |
| 3 | about.json has enable_welcome_banner set to false in theme_site_settings | VERIFIED | Line 36–38: `"theme_site_settings": { "enable_welcome_banner": false }` present; valid JSON |
| 4 | No inline style= attributes remain on elements inside tavern-banner.hbs | VERIFIED | grep for `style=` in tavern-banner.hbs returns no matches |
| 5 | No href="/new-topic" remains in tavern-banner.hbs | VERIFIED | grep for `new-topic` in tavern-banner.hbs returns no matches |
| 6 | tavern-banner.hbs CTA is a button wired to openNewTopic action | VERIFIED | Line 7: `<button type="button" class="tavern-banner__cta" {{on "click" this.openNewTopic}}>` |
| 7 | tavern-banner.js openNewTopic uses composer service for logged-in and router for anonymous | VERIFIED | Lines 27–30: `this.composer.openNewTopic({})` for logged-in; `this.router.transitionTo("login")` for anon |
| 8 | honored-patrons.js uses @tracked patrons = [] with no appEvents, _patrons, or sidebar:refresh | VERIFIED | Line 3: `tracked` imported; line 48: `@tracked patrons = []`; line 53: `this.patrons = users`; grep for `_patrons`, `appEvents`, `sidebar:refresh`, `api.container` returns no matches |
| 9 | common.scss has no @import for Google Fonts | VERIFIED | grep for `@import.*googleapis` returns no matches |
| 10 | common.scss has --tavern-brass driven by $accent_hue and BEM classes feature-link/feature-title | VERIFIED | Line 17: `--tavern-brass: hsl(#{$accent_hue}, 68%, 45%)`; lines 329/334: `&__feature-link` and `&__feature-title` blocks inside `.tavern-banner` scope |

**Score:** 10/10 truths verified (all automated checks pass)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `javascripts/discourse/api-initializers/theme-setup.js` | apiInitializer mounting TavernBanner at discovery-list-container-top | VERIFIED | 7-line file; correct import, guard, and renderInOutlet call |
| `about.json` | theme_site_settings with enable_welcome_banner: false | VERIFIED | Block present; color_schemes intact; valid JSON |
| `javascripts/discourse/components/tavern-banner.js` | openNewTopic action, composer + currentUser services | VERIFIED | action import, both services declared, action method wired correctly |
| `javascripts/discourse/components/tavern-banner.hbs` | Button CTA, BEM feature-link/feature-title classes, no inline styles | VERIFIED | All three conditions met |
| `javascripts/discourse/api-initializers/honored-patrons.js` | @tracked patrons reactivity, no appEvents | VERIFIED | tracked import added, @tracked patrons = [], direct assignment in constructor |
| `common/common.scss` | No @import googleapis, hsl accent_hue, BEM classes | VERIFIED | All three changes present in file |
| `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` | Must NOT exist (deleted) | VERIFIED | below-site-header directory does not exist |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| theme-setup.js | TavernBanner component | `import TavernBanner from "../components/tavern-banner"` + `api.renderInOutlet` | WIRED | Import on line 2; renderInOutlet on line 6 |
| about.json | Discourse WelcomeBanner suppression | `theme_site_settings.enable_welcome_banner: false` | WIRED | Key present at correct JSON path |
| tavern-banner.hbs button | openNewTopic action | `{{on "click" this.openNewTopic}}` | WIRED | Line 7 of hbs; action defined in .js lines 25–32 |
| tavern-banner.js openNewTopic | composer service | `this.composer.openNewTopic({})` | WIRED | @service composer declared line 13; called line 28 |
| tavern-banner.js openNewTopic | router service | `this.router.transitionTo("login")` | WIRED | @service router declared line 10; called line 30 |
| honored-patrons.js loadPatrons().then() | @tracked patrons | `this.patrons = users` in constructor | WIRED | Lines 52–54; @tracked on line 48 ensures Glimmer re-render |
| common.scss :root | --tavern-brass CSS variable | `hsl(#{$accent_hue}, 68%, 45%)` | WIRED | Line 17; $accent_hue is the SCSS variable exposed by Discourse for the accent_hue theme setting |
| tavern-banner.hbs feature anchor | common.scss &__feature-link | `class="tavern-banner__feature-link"` | WIRED | HBS line 34 applies class; SCSS lines 329–332 define it inside .tavern-banner scope |
| tavern-banner.hbs feature h3 | common.scss &__feature-title | `class="tavern-banner__feature-title"` | WIRED | HBS line 35 applies class; SCSS lines 334–340 define it inside .tavern-banner scope |

### Data-Flow Trace (Level 4)

Not applicable to this phase. Phase 1 fixes wiring and removes anti-patterns in existing components. No new data-rendering artifacts were introduced. The TavernBanner's data flow (ajax to /top.json, /latest.json, /badges.json) was pre-existing and unchanged.

### Behavioral Spot-Checks

Step 7b: SKIPPED — all behavioral outputs (banner render, composer open, sidebar populate, font requests, color change) require a live Discourse instance and cannot be verified without starting a server. These are routed to Human Verification.

### Requirements Coverage

| Requirement | Plan | Description | Status | Evidence |
|-------------|------|-------------|--------|---------|
| FOUND-01 | 01-01 | Banner renders exactly once on homepage above topic list | VERIFIED (code) | connector deleted; renderInOutlet in theme-setup.js; human test required to confirm single render |
| FOUND-02 | 01-01 | Discourse native WelcomeBanner disabled | VERIFIED | about.json `enable_welcome_banner: false` |
| FOUND-03 | 01-01 | Banner mount moved to discovery-list-container-top via api.renderInOutlet | VERIFIED | theme-setup.js line 6 |
| FOUND-04 | 01-02 | "Pull a Stool" opens composer instead of /new-topic | VERIFIED (code) | button wired to openNewTopic action using composer service; human test required |
| FOUND-05 | 01-03 | Honored Patrons populates on slow connections using @tracked | VERIFIED (code) | @tracked patrons, direct assignment, no appEvents; human test required |
| FOUND-06 | 01-03 | Google Fonts loaded exactly once, @import removed from SCSS | VERIFIED | @import line gone from common.scss; head_tag.html link tags unchanged |
| FOUND-07 | 01-02 + 01-03 | Inline style= removed from hbs, moved to SCSS classes | VERIFIED | No style= in hbs; BEM classes defined in common.scss |
| FOUND-08 | 01-03 | accent_hue wired to --tavern-brass CSS variable | VERIFIED (code) | hsl(#{$accent_hue}, 68%, 45%) on line 17; human test required to confirm color change |

No orphaned requirements: all 8 FOUND-0x requirements for Phase 1 are mapped to plans and verified above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| common/common.scss | 43 | `border-bottom: 1px solid #c8941a` (hardcoded brass hex) | Info | Does not use --tavern-brass variable; changing accent_hue won't shift this border. Affects header bottom border aesthetics only. |
| common/common.scss | 299 | `background: #c8941a` (hardcoded brass hex in &__cta) | Info | CTA button background won't respond to accent_hue changes. Low impact — CTA color is a brand constant. |

Neither is a blocker. The hardcoded hex values pre-date Phase 1 and were not in scope. The accent_hue requirement (FOUND-08) is satisfied by the `:root --tavern-brass` variable — the noted instances are cosmetic and separate from the requirement. Noted for Phase 3/4 polish if desired.

### Human Verification Required

#### 1. Single Banner Render

**Test:** Upload theme to Discourse. Load the homepage. Open DevTools → Elements. Search for `.tavern-banner`.
**Expected:** Exactly one `<section class="tavern-banner">` element in the DOM. No `.welcome-banner` element present.
**Why human:** Cannot verify DOM deduplication (api.renderInOutlet + WelcomeBanner suppression both active) without a live Discourse rendering context.

#### 2. Composer Opens for Logged-In User

**Test:** Log in as any test user. Load the homepage. Click the "Pull a Stool" button.
**Expected:** The Discourse new-topic composer opens as an overlay. The page does not navigate away. No console errors.
**Why human:** `this.composer.openNewTopic({})` requires a live Ember service container; cannot call the service from a static analysis.

#### 3. Login Redirect for Anonymous User

**Test:** Log out. Load the homepage. Click the "Pull a Stool" button.
**Expected:** Browser navigates to `/login`. No 404 response.
**Why human:** `this.router.transitionTo("login")` requires a live Ember routing context.

#### 4. Single Font Load (Network Tab)

**Test:** Open DevTools → Network tab. Filter by "font" or "googleapis". Hard-reload the homepage.
**Expected:** Exactly one request each for Playfair Display, Spectral, and Inter. No duplicate requests for the same font family.
**Why human:** HTTP request deduplication can only be observed in a live browser session.

#### 5. Honored Patrons Sidebar on Slow Connection

**Test:** In DevTools → Network → throttle to "Slow 3G". Hard-reload the homepage. Watch the sidebar "Honored Patrons" section.
**Expected:** After a delay (while the API call completes), patron names and avatars appear in the sidebar without a page refresh.
**Why human:** @tracked Glimmer reactivity requires a live rendering engine; the async patron-fetch timing cannot be simulated statically.

#### 6. accent_hue Admin Setting Updates Brass Color

**Test:** Admin → Customize → Themes → Liberty Tavern → Settings. Set "Accent Hue" to a visually distinct value (e.g., 200 for blue-teal). Save. Reload homepage.
**Expected:** The CTA button border color, header border, and any element using `--tavern-brass` shift to the new hue.
**Why human:** SCSS variable interpolation produces compiled CSS at Discourse's theme-compilation time; the output color cannot be confirmed without triggering a compile and page load.

### Gaps Summary

No gaps. All 10 observable truths pass automated verification. The 6 human verification items above are standard browser/UI confirmation steps that cannot be automated without a running Discourse instance — they are not indicative of implementation defects.

---

_Verified: 2026-04-26T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
