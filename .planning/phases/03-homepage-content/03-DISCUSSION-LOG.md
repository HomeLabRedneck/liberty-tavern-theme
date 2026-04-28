# Phase 3: Homepage Content — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 03-homepage-content
**Areas discussed:** Banner aside (stats panel), Trending Tonight layout, Room cards approach, Data loading

---

## Banner aside (stats panel)

| Option | Description | Selected |
|--------|-------------|----------|
| Stats only | Aside becomes 4-stat panel. Badges → Phase 4. | ✓ |
| Stats + badges stacked | Stats on top, badges below in same aside. | |
| Stats + keep Project of Night | Add stats, keep featured topic card too. | |

**User's choice:** Stats only — aside replaced entirely with "Tonight at the House" panel.
**Notes:** User confirmed "Project of the Night" is not in the design image (Image 4). Badges move to Phase 4 right column.

---

## Trending Tonight layout

| Option | Description | Selected |
|--------|-------------|----------|
| Move below banner | Separate section, cream background. Matches Image 4. | ✓ |
| Keep inside banner | Leave trending inside dark banner. | |

**Layout fidelity:**

| Option | Description | Selected |
|--------|-------------|----------|
| Match Image 4 exactly | Category label + title + author · replies · time ago | ✓ |
| Close but skip category label | Title + author + replies + time ago | |

**"ALL HOT THREADS →" link:**

| Option | Description | Selected |
|--------|-------------|----------|
| /hot | Trending now route | ✓ |
| /top | Best of time period | |

**Notes:** User confirmed trending should match Image 4 exactly. Time ago shown (not views count). Category label above title in small caps (e.g., THE TOWN SQUARE).

---

## Room cards approach

| Option | Description | Selected |
|--------|-------------|----------|
| Vertical list cards (Image 4) | Custom CSS on Discourse category list | |
| Grid boxes (categories_boxes) | Discourse built-in page style | ✓ |

**User's choice:** categories_boxes for Phase 3. Vertical list cards added to future feature request.
**Notes:** Image 4 technically shows vertical list layout, but user chose to defer that in favor of faster implementation using Discourse's built-in categories_boxes style.

---

## Data loading

| Option | Description | Selected |
|--------|-------------|----------|
| Parallel with Promise.all | Fetch /about.json + /top.json simultaneously | ✓ |
| Sequential, add /about.json last | Simplest change, stats load after trending | |

**User's choice:** Promise.all — aligns with v2 PERF-02 requirement.
**Notes:** /badges.json fetch also removed since badges no longer appear in banner.

---

## Claude's Discretion

- Trending section placement: second block in same template vs. second outlet render in theme-setup.js
- Time-ago formatting: inline helper, no external library
- Category name lookup: `this.site.categories` if available in GJS, else /categories.json call
- Stats loading state: placeholder dashes while /about.json loads

## Deferred Ideas

- Vertical list room cards (image 4 exact layout) — future Phase 5 or post-v1
- Badges in banner — removed, moved to Phase 4 right column
