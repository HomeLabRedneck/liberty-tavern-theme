---
phase: 3
plan: "03-01"
subsystem: frontend-component
tags: [glimmer, gjs, stats, trending, refactor]
dependency_graph:
  requires: []
  provides: [tavern-banner-stats, tavern-trending-strip]
  affects: [common.scss-section8, common.scss-section9]
tech_stack:
  added: [discourse/models/category]
  patterns: [Promise.all parallel fetch, module-scope GJS helpers, statRows getter, timeAgo helper]
key_files:
  modified:
    - javascripts/discourse/components/tavern-banner.gjs
decisions:
  - "Module-scope timeAgo() and toItem() functions used as GJS template helpers without import — available in <template> scope by GJS design"
  - "statRows getter chosen over (array ...) / (hash ...) Handlebars helpers — avoids Ember helper availability risk in Discourse GJS context"
  - "raw.slice(0,3) replaces raw.slice(1,4) — featured no longer consumes raw[0]"
  - ".tavern-trending rendered as sibling of section.tavern-banner inside same {{#if this.shouldShow}} block — no second outlet mount needed"
metrics:
  duration: "~20 minutes"
  completed: "2026-04-28"
  tasks_completed: 2
  files_modified: 1
---

# Phase 3 Plan 01: Tavern Banner JS + Template Refactor Summary

**One-liner:** Parallel /about.json + /top.json fetch with stats panel in aside and external trending strip as sibling div outside dark banner section.

## What Was Built

Refactored `javascripts/discourse/components/tavern-banner.gjs` (157 lines → 163 lines) to:

1. Fetch `/about.json` and `/top.json` in parallel via `Promise.all` (was sequential)
2. Map `/about.json` stats fields to a `this.stats` object with four keys: `patronsInside`, `members`, `postsToday`, `openRooms`
3. Replace dead `@tracked featured` and `@tracked badges` with `@tracked stats = null`
4. Remove `showBadges` getter and `/badges.json` fetch entirely
5. Add module-scope `timeAgo()` helper and enriched module-scope `toItem()` with `categoryName`, `author`, `bumpedAt` fields
6. Add `statRows` getter returning 4-item array for template iteration
7. Replace entire template: aside now holds `.tavern-banner__stats` panel with 4 rows; `.tavern-trending` rendered as sibling of `<section class="tavern-banner">` outside the dark banner

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 — JS refactor | `ba80a21` | Category import, timeAgo, toItem, stats tracked property, statRows getter, Promise.all loadData |
| Task 2 — Template refactor | `b30d4b3` | Stats panel in aside, external trending strip as sibling div |

## Success Criteria Verification

| Criterion | Status |
|-----------|--------|
| Promise.all fetches /about.json + /top.json in parallel | PASS — line 76 |
| this.stats set from aboutRes?.about?.stats with 4 keys | PASS — lines 82–88 |
| toItem() at module scope, returns categoryName/author/bumpedAt, no views/likeCount | PASS — lines 18–29 |
| @tracked featured and @tracked badges gone; @tracked stats = null present | PASS |
| Template emits .tavern-banner__stats in aside with 4 stat rows | PASS — lines 122–134 |
| .tavern-trending is sibling of section.tavern-banner, not nested inside | PASS — lines 139–159 |
| No style= attributes in template | PASS — grep returns 0 |
| timeAgo at module scope | PASS — line 10 |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Stats data flows from live `/about.json` API call. Trending data flows from live `/top.json` + `/latest.json` fallback. No hardcoded placeholder values in the data path (only the `"—"` em-dash shown while `this.loading` is true, which is the intended loading state, not a stub).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced beyond what the plan's threat model covers. Both `/about.json` and `/top.json` are public Discourse endpoints already in scope (T-03-01, T-03-03). `htmlSafe()` applied to topic titles in `toItem()` per T-03-02.

## Self-Check: PASSED

- `javascripts/discourse/components/tavern-banner.gjs` — EXISTS, 163 lines
- Commit `ba80a21` — EXISTS in git log
- Commit `b30d4b3` — EXISTS in git log
- `grep -c "export default class TavernBanner"` → 1
- `grep -c "tavern-banner__trending"` → 0
- `grep -c "this.featured"` → 0
- `grep -c "style="` → 0
- `grep -n "Promise.all"` → line 76 (1 occurrence)
