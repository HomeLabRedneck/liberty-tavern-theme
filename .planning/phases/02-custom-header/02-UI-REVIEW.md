# UI Review — Phase 02: Custom Header

**Audited:** 2026-04-28
**Overall Score:** 20/24
**Baseline:** 02-UI-SPEC.md

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | All spec copy exact — nav labels, logo title/tagline, Sign In |
| 2. Visuals | 3/4 | Logo hidden when `logo` setting empty (no fallback to theme asset) |
| 3. Color | 3/4 | Active pill uses filled brass box — spec prescribes 2px underline |
| 4. Typography | 3/4 | Phase 2 header values exact; `letter-spacing` on logo title not in spec |
| 5. Spacing | 4/4 | All Phase 2 spacing values match spec exactly |
| 6. Experience Design | 3/4 | `position: fixed` + 6× `!important` on nav-pills block; conflicting active-state rules |

---

## Priority Fixes

### P1 — Logo shows nothing when `logo` setting is empty

`tavern-logo.gjs` `get logoUrl()` returns `null` when `settings.logo` is empty string (the default). The `{{#if this.logoUrl}}` block skips the `<img>` entirely — admin sees text-only header until they manually upload a logo.

The original `.hbs` used `{{theme-asset "logo.png"}}` which worked zero-config from the committed asset file. The GJS migration lost this fallback.

**Fix:** Add `theme-asset` as fallback, or document the admin step prominently.

---

### P2 — Conflicting nav-pills active-state rules

Two blocks define active state differently:

1. Inside `.d-header {}` (lines ~90): `border-bottom: 2px solid var(--tavern-brass)` — spec-correct
2. `.navigation-container .nav-pills` block: `background: var(--tavern-brass) !important; border-bottom: none !important` — overrides #1

Block #2 wins. Users see filled brass box, not the spec's brass underline. The spec's State Table (Default/Hover/Active/Focus) is not implemented as written.

**Fix:** Consolidate into one block. Implement spec state table:
- Default: `#f5ebd9` opacity 0.85
- Hover: `var(--tavern-brass)` opacity 1.0
- Active: `#f5ebd9` opacity 1.0 + `border-bottom: 2px solid var(--tavern-brass)`
- Focus: `outline: 2px solid var(--tavern-brass)`

---

### P3 — `position: fixed` on nav-pills creates z-index risk

`.navigation-container .nav-pills` uses `position: fixed; z-index: 1001` to visually overlay the header. This:
- Places a non-header DOM element above Discourse's header (`z-index: 1000`)
- May conflict with modals, dropdowns, and tooltips
- Uses 6× `!important` making the block brittle against Discourse core updates
- Only renders on discovery routes — non-discovery pages (e.g. Subscribe) show no pills

**Fix:** Use `api.headerIcons.add()` with a GJS component (already implemented on `feature/persistent-header-nav` branch) — merge when ready.

---

## Minor Findings

- **Logo hex vs var:** `color: #f5ebd9` in `.tavern-logo__title` could reference `var(--tavern-cream)` — minor consistency issue, not a spec violation
- **Letter-spacing on logo title:** `letter-spacing: -0.01em` on `.tavern-logo__title` is not in spec's logo title contract — visually harmless
- **Nav pill padding:** `padding: 6px 14px` vs spec's 16px md spacing token — 2px off, visually negligible
