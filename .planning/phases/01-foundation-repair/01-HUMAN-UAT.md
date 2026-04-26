---
status: partial
phase: 01-foundation-repair
source: [01-VERIFICATION.md]
started: 2026-04-26T00:00:00Z
updated: 2026-04-26T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Single banner render in DOM
expected: Exactly one `<section class="tavern-banner">` in DOM. No `.welcome-banner` element present.
result: [pending]

### 2. Composer opens for logged-in user
expected: Click "Pull a Stool" while logged in → Discourse new-topic composer opens as overlay. No page navigation. No 404.
result: [pending]

### 3. Login redirect for anonymous user
expected: Click "Pull a Stool" while logged out → browser navigates to `/login`. No 404.
result: [pending]

### 4. Single font load (Network tab)
expected: Exactly one request each for Playfair Display, Spectral, and Inter. No duplicate font requests.
result: [pending]

### 5. Honored Patrons sidebar on slow connection
expected: Throttle to Slow 3G. After delay, patron names/avatars appear in sidebar without page refresh.
result: [pending]

### 6. accent_hue admin setting updates brass color
expected: Change accent_hue in Admin → Themes → Settings. Reload. Banner CTA and header border shift to new hue.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
