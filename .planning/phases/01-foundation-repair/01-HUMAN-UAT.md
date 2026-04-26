---
status: complete
phase: 01-foundation-repair
source: [01-VERIFICATION.md]
started: 2026-04-26T00:00:00Z
updated: 2026-04-26T00:00:00Z
---

## Current Test

[testing complete]

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

### 5. Honored Patrons sidebar on slow connection
expected: Throttle to Slow 3G. After delay, patron names/avatars appear in sidebar without page refresh.
result: issue
reported: "Honor Patrons, never loads for slow or fast. I think its broken."
severity: major
diagnosis: trust_level_4 is a Discourse system group — /groups/trust_level_4/members.json returns 403 for non-admin callers. .catch(() => []) swallows error silently. Section header shows (displaySection: true) but links stays empty. Fix: make trust_level_4 group publicly visible in Discourse Admin → Groups, or create a custom public group and update honored_patrons_group setting.

### 6. accent_hue admin setting updates brass color
expected: Change accent_hue in Admin → Themes → Settings. Reload. Banner CTA and header border shift to new hue.
result: issue
reported: "no color change"
severity: major
diagnosis: --tavern-brass CSS var is correctly wired to hsl(#{$accent_hue}, 68%, 45%) in :root, but the visible brass elements (header border line 43, CTA button line 299) still use hardcoded #c8941a instead of var(--tavern-brass). Fix: replace all #c8941a occurrences in common.scss with var(--tavern-brass).

## Summary

total: 6
passed: 3
issues: 2
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "Honored Patrons sidebar populates with patron names on page load"
  status: failed
  reason: "User reported: Honor Patrons, never loads for slow or fast. trust_level_4 group returns 403 via public API."
  severity: major
  test: 5
  artifacts: [javascripts/discourse/api-initializers/honored-patrons.js]
  missing: [Discourse Admin group visibility config OR custom group setup]

- truth: "Changing accent_hue admin setting visibly shifts brass color on CTA button and header border"
  status: failed
  reason: "User reported: no color change. Hardcoded #c8941a in .d-header border and &__cta background bypasses --tavern-brass variable."
  severity: major
  test: 6
  artifacts: [common/common.scss]
  missing: [Replace hardcoded #c8941a with var(--tavern-brass) throughout common.scss]
