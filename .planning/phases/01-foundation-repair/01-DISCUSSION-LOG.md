# Phase 1: Foundation Repair — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 01-foundation-repair
**Areas discussed:** Anonymous CTA behavior, Honored Patrons display, api-initializer structure

---

## Anonymous CTA Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Route to login page | `router.transitionTo('login')` — standard Discourse pattern | ✓ |
| Open login modal | Modal overlay without page navigation | |
| Hide button for anon users | Don't show CTA to logged-out users | |

**User's choice:** Route to login page
**Notes:** Standard Discourse pattern. User logs in and navigates back manually.

---

## Honored Patrons Display

| Option | Description | Selected |
|--------|-------------|----------|
| Name + trust tier (keep current) | Tier suffix: "Leader", "Regular", etc. Fix reactivity only | ✓ |
| Name + post count | Replace tier with post_count from group members API | |
| Name + avatar only | Clean minimal — no suffix | |

**User's choice:** Keep current (name + trust tier)
**Notes:** Only fix the reactivity bug. No display changes.

---

## api-initializer Structure

| Option | Description | Selected |
|--------|-------------|----------|
| New file: theme-setup.js | Dedicated initializer for theme-level setup | ✓ |
| Fold into honored-patrons.js | Fewer files but mixed concerns | |

**User's choice:** New file `theme-setup.js`
**Notes:** Will grow to handle Phase 2–4 setup as well.

---

## Claude's Discretion

- `shouldShow` route check approach (regex vs. `defaultHomepage()`)
- SCSS class names for removed inline styles
- accent_hue wiring mechanism (SCSS interpolation vs. head_tag.html)

## Deferred Ideas

None.
