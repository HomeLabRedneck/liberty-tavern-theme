---
plan: 01-02
phase: 01-foundation-repair
status: complete
completed: 2026-04-26
requirements: [FOUND-04, FOUND-07]
---

## What Was Built

Fixed the 404 CTA bug and eliminated all inline `style=` attributes from the banner template.

## Key Files

### Modified
- `javascripts/discourse/components/tavern-banner.js` — added `@action import`, `@service currentUser`, `@service composer`, and `openNewTopic()` action (composer for logged-in, router.transitionTo("login") for anon)
- `javascripts/discourse/components/tavern-banner.hbs` — replaced `<a href="/new-topic">` with `<button {{on "click" this.openNewTopic}}>`, replaced inline `style=` attrs on feature link/h3 with BEM classes `tavern-banner__feature-link` and `tavern-banner__feature-title`

## Decisions Made

- Per D-01: anonymous users route to login (not hidden button, not modal)
- BEM class names match PATTERNS.md conventions

## Self-Check: PASSED

- [x] No `href="/new-topic"` in hbs
- [x] No `style=` attributes in hbs
- [x] `openNewTopic` action present using `this.composer.openNewTopic({})`
- [x] `this.router.transitionTo("login")` for anon
- [x] `tavern-banner__feature-link` and `tavern-banner__feature-title` classes added
- [x] All changes committed
