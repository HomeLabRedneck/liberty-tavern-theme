---
status: partial
phase: 02-custom-header
source: [02-VERIFICATION.md]
started: 2026-04-27T00:00:00Z
updated: 2026-04-27T00:00:00Z
---

## Current Test

[awaiting human testing — upload theme to Discourse instance first]

## Tests

### 1. Logo, title, and tagline visible on all pages
expected: Every page (homepage, topic, /categories, profile) shows the tavern logo image, "The Liberty Tavern" title, and "Free Speech · Est. MDCCXCI" tagline in the header beside the logo
result: [pending]

### 2. Sign In button styled and labeled correctly
expected: Logged-out / incognito view shows a brass-colored button labeled "Sign In" (not "Log In") in the header that opens the Discourse login modal on click
result: [pending]

### 3. Nav pills show correct labels after admin top_menu change
expected: After setting Admin → Settings → top_menu = `hot|latest|categories|top`, nav pills read: Trending | Latest at the Bar | Rooms | Top Shelf — no `[missing "en.filters.latest.title" translation]` errors in browser console
result: [pending]

### 4. Native search and user-menu intact
expected: Search icon opens search overlay; user avatar (when logged in) opens user menu; both icons are visible and brass/cream colored
result: [pending]

### 5. No content-header overlap on any page
expected: Page content starts below the 64px header bar on homepage, topic pages, and category pages — no content hidden behind the header
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
