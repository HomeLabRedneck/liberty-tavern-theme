---
plan: 03-05
phase: 03-homepage-content
status: complete
completed: "2026-04-30"
commit: 844d376
---

# Plan 03-05 Summary: GJS Connector — Room Card Latest Topic Preview

## What Was Built

A Discourse plugin outlet connector that injects a latest-topic preview line into each room card, plus SCSS for the preview element.

## Key Files

### Created
- `javascripts/discourse/connectors/category-box-below-each-category/tavern-room-preview.gjs` — Glimmer connector component

### Modified
- `common/common.scss` — +37 lines `.tavern-room-preview` SCSS block (§6-ext-5)

## Tasks Completed

| Task | Status | Notes |
|------|--------|-------|
| 1: Determine outlet name | ✓ | `category-box-below-each-category` confirmed from Discourse Meta |
| 2: Create tavern-room-preview.gjs | ✓ | No inline styles, no ajax, pure args-based |
| 3: Add .tavern-room-preview SCSS | ✓ | Chevron uses var(--category-badge-color), 2-line clamp |

## Outlet Name Research

**Chosen name:** `category-box-below-each-category`

**Evidence:** Discourse Meta official deprecation notice (meta.discourse.org/t/327580) shows this exact outlet name in code examples:
```
<PluginOutlet @name="category-box-below-each-category" @outletArgs={{hash category=c}} />
```
This outlet is used by "discourse-minimal-category-boxes" and the Air theme. The `@outletArgs={{hash category=c}}` confirms `this.args.category` is the Category model in the connector.

## Self-Check: PASSED

- Connector directory `category-box-below-each-category` exists ✓
- `import Component from "@glimmer/component"` present ✓
- Both `latestTopicTitle` and `latest_topic_title` in null-coalescing getter ✓
- `{{#if this.latestTitle}}` guard present ✓
- Zero `style=` attributes ✓
- Zero `ajax`, `@service`, `@tracked` (pure args component) ✓
- `.tavern-room-preview` SCSS block before "---- 7. Buttons" ✓
- `var(--category-badge-color, var(--tertiary))` chevron color ✓
- `-webkit-line-clamp: 2` text truncation ✓

## Graceful Degradation

If `category.latestTopicTitle` is not exposed by this Discourse install's serializer, `latestTitle` returns `null`, the `{{#if}}` guard fires, and the connector renders nothing. Cards look like 03-04 state. No error thrown, no broken layout.

If the outlet name is ever wrong, the component silently never mounts — same safe degradation.

## Requirements Covered

- ROOM-02: Featured topic preview line per card (chevron + title)
- ROOM-04: Preview title color #6B5A47 per ColorSpec §3.4
