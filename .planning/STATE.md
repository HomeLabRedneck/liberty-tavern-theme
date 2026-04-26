# Project State: Liberty Tavern Discourse Theme

**Initialized:** 2026-04-26
**Last updated:** 2026-04-26

## Project Reference

**Core Value:** The homepage must look and function like the Image 1 design — custom header, styled banner with live stats, trending section, and room cards.

**Current Focus:** Phase 1 context captured. Ready to plan Phase 1 (Foundation Repair).

## Current Position

- **Milestone:** v1 (initial release matching Image 1)
- **Phase:** 1 — Foundation Repair (in progress — plan 04 complete, plans 01–03 pending)
- **Plan:** 04 complete
- **Status:** In progress
- **Progress:** `[----] 0/4 phases complete`

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases planned | 1 / 4 |
| Phases complete | 0 / 4 |
| Requirements validated | 2 / 26 |
| Plans complete | 1 / 4 |

## Accumulated Context

### Key Decisions

- **Coarse granularity, 4 phases** — Project scope is bounded by Image 1 fidelity, not arbitrary scaling; 4 phases match natural delivery boundaries (foundation → header → homepage content → right column).
- **YOLO mode** — Single non-technical owner; no review gates between phases.
- **Phase ordering driven by blast radius** — Foundation first (kills the most visible bug and validates the new outlet pattern), right-column last (touches `#main-outlet-wrapper` grid).

### Decisions Locked (01-04)

- **honored_patrons_group default empty** — sidebar hidden until admin configures a real publicly-visible group; avoids 403 from restricted system groups
- **filter: brightness(1.15) for hover states** — lighten() cannot operate on CSS custom properties (runtime values); brightness() preserves accent_hue responsiveness on hover
- **var(--tavern-cream) for sidebar background** — --secondary-low resolves dark on this Discourse install; explicit cream variable is always correct

### Decisions Pending

- Verify on live Discourse instance before Phase 1: cause of banner duplication (WelcomeBanner vs outlet scope vs both), `enable_welcome_banner` current value, exact `/about.json` field names, Discourse minor version. Defaults documented in `research/SUMMARY.md` allow Phase 1 to proceed without these answers.

### Open Todos

- [x] Plan Phase 1 via `/gsd-plan-phase 1`
- [ ] Execute Phase 1 via `/gsd-execute-phase 1`
- [ ] (Optional) Verify the 5 open questions in `research/SUMMARY.md` section 5 against the live forum

### Blockers

None.

## Session Continuity

**Last action:** Executed plan 01-04 — 4 UAT fixes (honored patrons guard, accent_hue wiring, eyebrow text, sidebar background). Commits: d1a3fdc, 52d20e2, dfb9e3b.

**Next action:** Execute plans 01-01, 01-02, 01-03 (banner outlet fix, CTA + inline styles, SCSS cleanup).

**Files of record:**
- `.planning/PROJECT.md` — vision, constraints, decisions
- `.planning/REQUIREMENTS.md` — 26 v1 requirements with traceability
- `.planning/ROADMAP.md` — 4 phases with goals and success criteria
- `.planning/research/SUMMARY.md` — research synthesis (stack recommendations, pitfalls)
- `.planning/config.json` — coarse granularity, YOLO mode

---
*State initialized: 2026-04-26*
