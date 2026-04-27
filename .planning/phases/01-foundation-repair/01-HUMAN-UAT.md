---
status: partial
phase: 01-foundation-repair
source: [01-VERIFICATION.md]
started: 2026-04-26T00:00:00Z
updated: 2026-04-26T00:00:00Z
---

## Current Test

[plan 01-04 fixes applied — awaiting browser re-verification of tests 5–8]

## Tests

### 1. Single banner render in DOM
expected: Exactly one `<section class="tavern-banner">` in DOM. No `.welcome-banner` element present.
result: pass

### 2. Composer opens for logged-in user
expected: Click "Pull a Stool" while logged in → Discourse new-topic composer opens as overlay. No page navigation. No 404.
result: pass

### 3. Login redirect for anonymous user
expected: Click "Pull a Stool" while logged out → browser navigates to `/login`. No 404.
result: skipped

### 4. Single font load (Network tab)
expected: Exactly one request each for Playfair Display, Spectral, and Inter. No duplicate font requests.
result: pass
note: HAR analysis confirmed 1 font request (parser-initiated via head_tag.html link tag)

### 5. Honored Patrons sidebar hidden by default / loads with real group
expected: With empty honored_patrons_group setting (new default), Honored Patrons section must not appear. When admin sets a valid public group, section appears and populates with patron names/avatars.
result: pending
fix_applied: plan 01-04 — honored_patrons_group default changed to ""; if (!groupName) return; guard added

### 6. accent_hue admin setting updates brass color
expected: Change accent_hue in Admin → Themes → Settings. Reload. Banner CTA, header border, trending prefix, badge icons all shift to new hue.
result: pending
fix_applied: plan 01-04 — all 12 hardcoded #c8941a replaced with var(--tavern-brass) / filter:brightness(1.15)

### 7. Banner eyebrow text = "✦ WELCOME, FRIEND ✦"
expected: Banner eyebrow (CSS ::before pseudo-element) reads "✦ WELCOME, FRIEND ✦", not "A NIGHTLY PRIMER".
result: pending
fix_applied: plan 01-04 — content changed from '★ A NIGHTLY PRIMER ★' to '✦ WELCOME, FRIEND ✦'

### 8. Sidebar background color is cream
expected: Left sidebar has warm cream background matching --tavern-cream (#f5ebd9). DevTools computed background-color = rgb(245, 235, 217).
result: pending
fix_applied: plan 01-04 — background changed from var(--secondary-low, #ede0c7) to var(--tavern-cream)

### 9. Header navigation pills present [PHASE 2 SCOPE]
expected: Top bar shows Trending, Rooms (pill-style), Latest at the Bar, Top Shelf navigation links (matching design Image 2 / Image 4).
result: issue
reported: "The navigation pill buttons are not in the top bar."
severity: major
phase_scope: Phase 2 (Custom Header) — not yet implemented. This is expected for Phase 1 UAT. Document here for traceability.

### 10. Header site title and tagline present [PHASE 2 SCOPE]
expected: Top bar shows "The Liberty Tavern" in Playfair Display italic and "FREE SPEECH · EST. MDCCXCI" tagline to the right of the logo.
result: issue
reported: "Same images top bar left title is missing, logo is there."
severity: major
phase_scope: Phase 2 (Custom Header) — not yet implemented. Expected for Phase 1 UAT.

### 11. Banner content structure matches design [PHASE 3 SCOPE]
expected: Banner aside shows "Tonight at the House" stats panel (Patrons Inside, Members, Posts Today, Open Rooms in italic gold). Trending Tonight, Rooms, Badges/House Rules render as separate sections below the banner.
result: issue
reported: "There are too many items in the nightly primer block — Project of the Night and Recent Badges are showing in the banner aside instead of the stats panel."
severity: major
phase_scope: Phase 3 (Homepage Content) — current aside renders `__feature` (Project of the Night with topic) and `__badges` (Recent Badges Awarded). Stats panel block not yet built. Trending strip is embedded in banner main; design shows it as a separate section below. Full restructure deferred to Phase 3.

## Summary

total: 11
passed: 3
issues: 3
pending: 4
skipped: 1
blocked: 0

## Gaps

- truth: "Honored Patrons sidebar hidden by default; populates when admin configures real group"
  status: pending
  reason: "Code fix applied in plan 01-04 — awaiting browser confirmation"
  test: 5

- truth: "Changing accent_hue admin setting visibly shifts brass color on all brass elements"
  status: pending
  reason: "Code fix applied in plan 01-04 — awaiting browser confirmation"
  test: 6

- truth: "Banner eyebrow reads ✦ WELCOME, FRIEND ✦"
  status: pending
  reason: "Code fix applied in plan 01-04 — awaiting browser confirmation"
  test: 7

- truth: "Sidebar background is cream (#f5ebd9)"
  status: pending
  reason: "Code fix applied in plan 01-04 — awaiting browser confirmation"
  test: 8
