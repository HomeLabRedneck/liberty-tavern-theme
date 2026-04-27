---
phase: 01-foundation-repair
verified: 2026-04-26T08:30:00Z
status: human_needed
score: 14/14 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 10/10
  gaps_closed:
    - "All hardcoded #c8941a replaced with var(--tavern-brass) — accent_hue now wired to every brass element"
    - "Banner eyebrow reads '✦ WELCOME, FRIEND ✦' (was '★ A NIGHTLY PRIMER ★')"
    - "Sidebar background uses var(--tavern-cream) instead of dark --secondary-low"
    - "honored_patrons_group default changed to empty string; if (!groupName) return guard added"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Load the homepage in a browser. Inspect the DOM for elements with class 'tavern-banner'."
    expected: "Exactly one .tavern-banner section element appears, positioned above the topic list. No second banner or welcome-banner element is present."
    why_human: "api.renderInOutlet wiring and WelcomeBanner suppression are code-only checks; actual DOM deduplication requires a live Discourse install."
  - test: "Log in as a test user. Click the 'Pull a Stool' button in the banner."
    expected: "The Discourse new-topic composer opens as an overlay. No page navigation occurs. No console errors or 404."
    why_human: "composer.openNewTopic() is a Discourse service call; whether the composer actually opens requires a running Discourse instance."
  - test: "Log out. Click the 'Pull a Stool' button in the banner."
    expected: "Browser navigates to /login. No 404."
    why_human: "router.transitionTo('login') requires a live Ember routing context to verify the transition fires correctly."
  - test: "Open browser DevTools → Network tab. Load the homepage with cache disabled."
    expected: "Exactly one request each for Playfair Display, Spectral, and Inter from fonts.googleapis.com. No duplicate font requests."
    why_human: "Duplicate @import removal is verified in code, but actual HTTP deduplication requires observing live network requests."
  - test: "Admin → Customize → Themes → Liberty Tavern → Settings. Change the 'Accent Hue' slider to 200 (blue). Save. Hard-reload the homepage."
    expected: "The header bottom border, the banner CTA button, the trending heading prefix dot, the badge icons, and the feature card label all visibly shift to a blue-toned color. Change back to 25 to restore brass."
    why_human: "SCSS variable interpolation produces compiled CSS at Discourse's theme-compilation time; the output color cannot be confirmed without triggering a compile and page load. UAT Test 6 confirmed the prior code was broken (hardcoded hex bypassed the variable); Plan 04 replaced all 12 occurrences — live confirmation required."
  - test: "Throttle connection to Slow 3G in DevTools. Load homepage. Set honored_patrons_group to a real publicly visible group in Admin settings. Observe the 'Honored Patrons' sidebar section."
    expected: "Patron names/avatars appear after a delay, without requiring a page refresh. Section does not stay empty. If honored_patrons_group is empty (default), the section must not appear at all."
    why_human: "@tracked Glimmer reactivity and the empty-guard early-return both require a live Glimmer rendering context. UAT Test 5 confirmed the prior code failed; Plan 04 added the guard and changed the default — live confirmation required."
  - test: "Inspect the banner eyebrow pseudo-element in DevTools (section.tavern-banner::before computed content)."
    expected: "Content reads '✦ WELCOME, FRIEND ✦' with the ✦ (U+2726) character. No '★' or 'NIGHTLY PRIMER' text visible."
    why_human: "CSS ::before content is computed at render time. UAT Test 7 confirmed the prior code showed wrong text; Plan 04 changed the string — live confirmation required."
  - test: "Inspect the left sidebar background in DevTools → .sidebar-wrapper computed background-color."
    expected: "Computed value is rgb(245, 235, 217) (equivalent to #f5ebd9 / --tavern-cream). Not a dark charcoal color."
    why_human: "CSS custom property resolution (--tavern-cream vs --secondary-low) requires a live Discourse rendering context. UAT Test 8 confirmed the prior code resolved to dark charcoal; Plan 04 changed to var(--tavern-cream) — live confirmation required."
---

# Phase 1: Foundation Repair — Verification Report

**Phase Goal:** Eliminate the visible bugs blocking everything else — banner duplication, 404 CTA, flaky sidebar, font/styling debt — so the homepage banner renders correctly once and the codebase is stable enough to build on.
**Verified:** 2026-04-26T08:30:00Z
**Status:** human_needed
**Re-verification:** Yes — after Plan 04 gap closure (4 UAT issues: Tests 5–8)

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Banner outlet connector file does not exist | VERIFIED | `connectors/` directory contains only `above-header/` (empty); no `below-site-header/` directory |
| 2  | theme-setup.js mounts TavernBanner via api.renderInOutlet at discovery-list-container-top | VERIFIED | Line 6: `api.renderInOutlet("discovery-list-container-top", TavernBanner)` guarded by `settings.show_homepage_banner` |
| 3  | about.json has enable_welcome_banner set to false in theme_site_settings | VERIFIED | Lines 36–38: `"theme_site_settings": { "enable_welcome_banner": false }` |
| 4  | tavern-banner.hbs CTA is a button wired to openNewTopic action | VERIFIED | Line 7: `<button type="button" class="tavern-banner__cta" {{on "click" this.openNewTopic}}>` |
| 5  | No href="/new-topic" remains in tavern-banner.hbs | VERIFIED | grep for `new-topic` returns no matches |
| 6  | tavern-banner.js openNewTopic uses composer for logged-in and router for anonymous | VERIFIED | Lines 27–30: `this.composer.openNewTopic({})` for logged-in; `this.router.transitionTo("login")` for anon |
| 7  | No inline style= attributes in tavern-banner.hbs | VERIFIED | grep for `style=` returns no matches |
| 8  | honored-patrons.js uses @tracked patrons = [] with direct assignment; no appEvents / _patrons / sidebar:refresh | VERIFIED | Line 3: `import { tracked }`; line 49: `@tracked patrons = []`; line 53–55: `this.patrons = users`; grep for `_patrons`, `appEvents`, `sidebar:refresh`, `api.container` returns no matches |
| 9  | honored_patrons_group default is empty string; if (!groupName) return guard present | VERIFIED | settings.yml line 52: `default: ""`; honored-patrons.js lines 8–9: `const groupName = settings.honored_patrons_group; if (!groupName) return;` |
| 10 | common.scss has no @import for Google Fonts | VERIFIED | grep for `@import.*googleapis` returns no matches; head_tag.html still has three `<link>` tags |
| 11 | common.scss has zero hardcoded #c8941a occurrences | VERIFIED | grep count returns 0; `var(--tavern-brass)` appears 11 times; `lighten()` appears 0 times; `filter: brightness(1.15)` appears on hover states for `.btn-primary` and `.__cta` |
| 12 | --tavern-brass driven by hsl(#{$accent_hue}, 68%, 45%) | VERIFIED | Line 17: `--tavern-brass: hsl(#{$accent_hue}, 68%, 45%)` in `:root` block |
| 13 | Banner eyebrow reads '✦ WELCOME, FRIEND ✦' | VERIFIED | Line 260: `content: '✦ WELCOME, FRIEND ✦'`; grep for 'NIGHTLY PRIMER' returns no matches |
| 14 | Sidebar background uses var(--tavern-cream) | VERIFIED | Line 77: `background: var(--tavern-cream)`; grep for `secondary-low` returns no matches in file |

**Score:** 14/14 truths verified (all automated checks pass)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `javascripts/discourse/api-initializers/theme-setup.js` | apiInitializer mounting TavernBanner at discovery-list-container-top | VERIFIED | 7-line file; correct import, guard, and renderInOutlet call |
| `about.json` | theme_site_settings with enable_welcome_banner: false | VERIFIED | Block present at lines 36–38; color_schemes intact; valid JSON |
| `javascripts/discourse/components/tavern-banner.js` | openNewTopic action, composer + currentUser services | VERIFIED | `@action` import, both services declared at lines 12–13, action defined at lines 25–32 |
| `javascripts/discourse/components/tavern-banner.hbs` | Button CTA with on-click, BEM feature-link/feature-title classes, no inline styles | VERIFIED | All three conditions met |
| `javascripts/discourse/api-initializers/honored-patrons.js` | @tracked patrons reactivity, groupName guard, no appEvents | VERIFIED | tracked import, @tracked patrons = [], guard at line 9, direct assignment at line 54 |
| `common/common.scss` | No @import googleapis, hsl accent_hue, BEM classes, no #c8941a, correct eyebrow, cream sidebar | VERIFIED | All six conditions confirmed |
| `settings.yml` | honored_patrons_group default empty string | VERIFIED | Line 52: `default: ""` |
| `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` | Must NOT exist (deleted) | VERIFIED | No `below-site-header` directory exists; only `above-header/` (empty) present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| theme-setup.js | TavernBanner component | `import TavernBanner` + `api.renderInOutlet` | WIRED | Import line 2; renderInOutlet line 6 |
| about.json | Discourse WelcomeBanner suppression | `theme_site_settings.enable_welcome_banner: false` | WIRED | Key present at correct JSON path |
| tavern-banner.hbs button | openNewTopic action | `{{on "click" this.openNewTopic}}` | WIRED | Line 7 of hbs; action defined in .js lines 25–32 |
| tavern-banner.js openNewTopic | composer service | `this.composer.openNewTopic({})` | WIRED | @service composer line 13; called line 28 |
| tavern-banner.js openNewTopic | router service | `this.router.transitionTo("login")` | WIRED | @service router line 10; called line 30 |
| honored-patrons.js loadPatrons().then() | @tracked patrons | `this.patrons = users` | WIRED | Lines 53–55; @tracked on line 49 ensures Glimmer re-render |
| honored-patrons.js entry | groupName guard | `if (!groupName) return` | WIRED | Line 9; settings.yml default "" ensures guard triggers by default |
| common.scss :root | --tavern-brass CSS variable | `hsl(#{$accent_hue}, 68%, 45%)` | WIRED | Line 17 |
| common.scss brass elements (11 sites) | --tavern-brass variable | `var(--tavern-brass)` at each use site | WIRED | 11 occurrences; 0 hardcoded #c8941a remaining |
| tavern-banner.hbs feature anchor | common.scss &__feature-link | `class="tavern-banner__feature-link"` | WIRED | HBS line 34; SCSS lines 329–332 inside .tavern-banner scope |
| tavern-banner.hbs feature h3 | common.scss &__feature-title | `class="tavern-banner__feature-title"` | WIRED | HBS line 35; SCSS lines 334–340 inside .tavern-banner scope |

### Data-Flow Trace (Level 4)

Not applicable to this phase. Phase 1 fixes wiring and removes anti-patterns. No new data-rendering artifacts were introduced. The TavernBanner's data flow (ajax to /top.json, /latest.json, /badges.json) was pre-existing and unchanged.

### Behavioral Spot-Checks

Step 7b: SKIPPED — all behavioral outputs (banner render, composer open, sidebar populate, font requests, color change) require a live Discourse instance and cannot be verified without starting a server. These are routed to Human Verification.

### Requirements Coverage

| Requirement | Plan | Description | Status | Evidence |
|-------------|------|-------------|--------|---------|
| FOUND-01 | 01-01 | Banner renders exactly once on homepage above topic list | VERIFIED (code) | Connector deleted; renderInOutlet in theme-setup.js; live DOM check = human test 1 |
| FOUND-02 | 01-01 | Discourse native WelcomeBanner disabled | VERIFIED | about.json `enable_welcome_banner: false` |
| FOUND-03 | 01-01 | Banner mount moved to discovery-list-container-top via api.renderInOutlet | VERIFIED | theme-setup.js line 6 |
| FOUND-04 | 01-02 | "Pull a Stool" opens composer instead of /new-topic | VERIFIED (code) | Button wired to openNewTopic action using composer service; live check = human test 2 |
| FOUND-05 | 01-03 + 01-04 | Honored Patrons populates on slow connections using @tracked; hidden when group not configured | VERIFIED (code) | @tracked patrons, direct assignment, no appEvents; empty-default + guard; live check = human test 6 |
| FOUND-06 | 01-03 | Google Fonts loaded exactly once, @import removed from SCSS | VERIFIED | @import line gone from common.scss; head_tag.html link tags unchanged |
| FOUND-07 | 01-02 + 01-03 | Inline style= removed from hbs, moved to SCSS BEM classes | VERIFIED | No style= in hbs; BEM classes defined in common.scss |
| FOUND-08 | 01-03 + 01-04 | accent_hue wired to --tavern-brass; all brass elements use the variable | VERIFIED (code) | hsl(#{$accent_hue}) in :root; 11 var(--tavern-brass) references; 0 hardcoded #c8941a; live check = human test 5 |

No orphaned requirements: all 8 FOUND-0x requirements for Phase 1 are mapped to plans and verified above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| common/common.scss | 304 | `border-bottom: 2px solid #2a1f17` in `&__cta--ghost` | Info | Hardcoded ink color (not brass) — expected; ghost CTA is intentionally dark-bordered |
| common/common.scss | 244 | `background: darken(#7a1f1f, 6%)` in `.btn-primary:hover` | Info | SCSS `darken()` on a compile-time literal — not a runtime variable, acceptable for a static brand color; not related to accent_hue wiring |

Neither is a blocker. The Plan 04 brass-wiring task correctly replaced the 10 static `#c8941a` uses and 2 `lighten()` hover states with `var(--tavern-brass)` and `filter: brightness(1.15)` respectively. The remaining `darken()` call operates on `--tavern-oxblood` (a fixed brand color, not the accent_hue-driven brass), so it is intentionally a static value.

### Human Verification Required

#### 1. Single Banner Render

**Test:** Upload theme to Discourse. Load the homepage. Open DevTools → Elements. Search for `.tavern-banner`.
**Expected:** Exactly one `<section class="tavern-banner">` element in the DOM. No `.welcome-banner` element present.
**Why human:** Cannot verify DOM deduplication (api.renderInOutlet + WelcomeBanner suppression both active) without a live Discourse rendering context.

#### 2. Composer Opens for Logged-In User

**Test:** Log in as any test user. Load the homepage. Click the "Pull a Stool" button.
**Expected:** The Discourse new-topic composer opens as an overlay. The page does not navigate away. No console errors.
**Why human:** `this.composer.openNewTopic({})` requires a live Ember service container; cannot call the service from static analysis. UAT Test 2 previously confirmed this passes.

#### 3. Login Redirect for Anonymous User

**Test:** Log out. Load the homepage. Click the "Pull a Stool" button.
**Expected:** Browser navigates to `/login`. No 404.
**Why human:** `this.router.transitionTo("login")` requires a live Ember routing context. UAT Test 3 was skipped previously.

#### 4. Single Font Load (Network Tab)

**Test:** Open DevTools → Network tab. Filter by "font" or "googleapis". Hard-reload the homepage.
**Expected:** Exactly one request each for Playfair Display, Spectral, and Inter. No duplicate requests for the same font family.
**Why human:** HTTP request deduplication can only be observed in a live browser session. UAT Test 4 previously confirmed this passes.

#### 5. accent_hue Admin Setting Updates All Brass Elements (Plan 04 fix confirmation)

**Test:** Admin → Customize → Themes → Liberty Tavern → Settings. Set "Accent Hue" to 200 (blue-teal). Save. Hard-reload the homepage.
**Expected:** The header bottom border, the banner CTA button background, the trending heading prefix dot (✦), the badge icon backgrounds, and the feature card label all visibly shift to a blue-toned color. Hover states on CTA and header sign-in button also shift (via filter: brightness).
**Why human:** Plan 04 replaced all 12 hardcoded `#c8941a` values with `var(--tavern-brass)`. UAT Test 6 confirmed the prior code was broken; this is the post-fix live confirmation.

#### 6. Honored Patrons Sidebar Behavior (Plan 04 fix confirmation)

**Test A (hidden by default):** With `honored_patrons_group` set to empty string (default), load the homepage. The "Honored Patrons" sidebar section must not appear — no section header, no empty link list.
**Test B (populates with real group):** In Admin, create a publicly visible group. Add test users. Set `honored_patrons_group` to that group name. Throttle to Slow 3G. Load homepage. Watch the sidebar.
**Expected B:** After API call completes, patron names/avatars appear without page refresh.
**Why human:** Guard early-return and @tracked reactivity both require a live Glimmer rendering context. UAT Test 5 confirmed the prior code was broken; this is the post-fix live confirmation.

#### 7. Banner Eyebrow Text (Plan 04 fix confirmation)

**Test:** Load the homepage. Open DevTools → Elements. Inspect `section.tavern-banner::before` computed content.
**Expected:** Content reads `✦ WELCOME, FRIEND ✦` with literal ✦ (U+2726) characters. No "★" or "NIGHTLY PRIMER" text visible anywhere on the banner.
**Why human:** CSS `::before` content is computed at render time. UAT Test 7 confirmed the prior code showed wrong text; this is the post-fix live confirmation.

#### 8. Sidebar Background Color is Cream (Plan 04 fix confirmation)

**Test:** Load the homepage. Open DevTools → inspect `.sidebar-wrapper` → computed `background-color`.
**Expected:** Computed value is `rgb(245, 235, 217)` or equivalent (which is `#f5ebd9` / `--tavern-cream`). Not dark charcoal.
**Why human:** CSS custom property resolution requires a live Discourse rendering context. UAT Test 8 confirmed the prior code resolved to dark charcoal; this is the post-fix live confirmation.

### Gaps Summary

No code-level gaps. All 14 observable truths pass automated verification. Plan 04 closed the 4 UAT issues identified during live testing (Tests 5–8): the codebase now correctly guards against empty group configuration, wires all brass color uses to the admin-adjustable variable, and uses the correct text strings for eyebrow and sidebar background.

The 8 human verification items above are live-browser confirmation steps that cannot be automated without a running Discourse instance. Items 1–4 carry forward from the initial verification; items 5–8 are new post-Plan-04 confirmations.

---

_Verified: 2026-04-26T08:30:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes (previous status: human_needed, 10/10; current: human_needed, 14/14)_
