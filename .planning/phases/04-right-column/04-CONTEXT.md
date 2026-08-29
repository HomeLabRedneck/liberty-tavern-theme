---
context: phase
phase: 04-right-column
source: user-provided mockups (4 homepage views), 2026-08-29
status: locked
---

# Phase 4 — Right Column: Locked Design Decisions

The user provided four annotated mockups (homepage views: Rooms, Trending, Latest at
the Bar, Top Shelf), all showing the same right-column rail. These mockups ARE the
design contract — decisions below are LOCKED, do not re-ask.

## D-1 — Rail placement & scope (COL-01, COL-02)
- A right-column rail appears BESIDE the main content on the homepage discovery views:
  **Rooms** (`.category-boxes`), **Trending**, **Latest at the Bar**, **Top Shelf**
  (all `.topic-list`). Same rail, same content, on every one of these list views.
- On the **Rooms** view the rail starts BELOW the full-width dark banner (the banner and
  its "Tonight at the House" stats box span the full content width; the rail begins at the
  Trending strip / Rooms list row). On the other three views (no banner) the rail starts
  near the top, aligned with the topic-list heading.
- Breakpoint: rail visible at **≥1160px**; **hidden below 1160px** with main content
  reflowing to full width — no horizontal scroll, no broken layout.
- Rail width ≈ 280px (final value at planner discretion), gutter ≈ 32px between main and rail.
- Real Discourse markup to target (from the mockup footer note):
  `.d-header · .custom-homepage-banner · .category-boxes / .category-box · .topic-list ·
  .sidebar-section`. Mount via a connector at `after-main-outlet`; CSS Grid override on the
  homepage content wrapper, scoped to discovery routes.

## D-2 — Panel visual style
- **Cream/parchment panels** (NOT dark). They sit on the cream page beside the room cards
  and topic list and share that light language. Dark is used only by the banner's stats box.

## D-3 — Badges panel (COL-03)
- Section header: **"Badges"** in Playfair Display, italic, weight 900, large (~24–26px),
  dark ink (#1C1410), with a thin horizontal rule beneath it spanning the rail width
  (oxblood/brass hairline).
- **2-column grid of the TOP 4 most-awarded badges** (2×2). Sort badges by grant count
  descending, take 4. (Data: `/badges.json` → each badge has `name`, `grant_count`,
  `badge_type_id`, `icon`/`image_url`.)
- Each badge tile:
  - Background: a slightly deeper cream tile (~#E8DCC0) with a 1px hairline border, small
    padding, centered content.
  - **Hexagon icon** at top — a hexagon filled with the badge's tier color, glyph in cream.
    Tier→color mapping (badge_type_id): gold(1) → brass `var(--tavern-brass)`,
    silver(2) → slate `#808281`, bronze(3) → copper `#8C6238`. (Mockup shows grey/blue/red/gold
    across the four sample badges — illustrative; use the tier mapping.)
  - Badge **name** below the hexagon: Inter, ~11px, weight 700, small-caps / uppercase,
    letter-spaced, dark ink.
  - **Grant count** below the name: e.g. `8421 EARNED` — Inter ~9px, weight 700, letter-spaced,
    muted (#6B5A47). Format: `{grant_count} EARNED`.
  - Sample badges shown in mockup: First Post (8421 earned), Hundred Posts (612), Town Crier
    (41), Founding Patron (12).

## D-4 — House Rules panel (COL-04)
- Eyebrow header: **"HOUSE RULES"** — Inter, ~10px, weight 700, uppercase, letter-spaced
  (~0.18em), oxblood (`var(--tavern-oxblood)`), with a small brass tick/accent to its left.
- A box bordered by a 1px **oxblood** hairline, cream interior, padding ~14px.
- A **numbered list of exactly 4 rules** (serif, Spectral, ~13px, dark ink, line-height ~1.7),
  numerals part of the list:
  1. Mind thy manners.
  2. Argue ideas, not the man.
  3. Cite thy sources.
  4. The barkeep's word is final.
- Rule text is LOCKED to the four lines above (from the mockup). Store as theme settings or
  I18n so an admin can edit later, but ship these four as the defaults.

## D-5 — Consistency with existing design system
- Reuse the existing tokens/vars from `common.scss` `:root` (cream, oxblood, brass, ink,
  rule) and the loaded fonts (Playfair Display / Spectral / Inter). No new fonts, no `@import`.
- The "Badges" header treatment mirrors the existing "The Rooms" section header; the
  small-caps eyebrow + hairline-box mirrors the Trending strip + stats-panel patterns.

## Requirements covered
- COL-01 rail beside main ≥1160px · COL-02 hidden <1160px · COL-03 badges grid ·
  COL-04 four house rules list.

## Open items for the planner (not user decisions)
- Exact selector for the homepage content wrapper grid override (verify live: is it
  `#main-outlet-wrapper`, `.list-container`, or the regenerated outlet wrapper on this
  Discourse version) — confirm in the browser before finalizing, same as Phase 3.
- Whether `after-main-outlet` is the correct outlet on this Discourse version, or whether a
  discovery-list outlet is needed so the rail also mounts on `.topic-list` views — verify live.
