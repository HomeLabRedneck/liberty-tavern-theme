---
plan: 01-01
phase: 01-foundation-repair
status: complete
completed: 2026-04-26
requirements: [FOUND-01, FOUND-02, FOUND-03]
---

## What Was Built

Fixed the banner duplication bug by applying both required fixes simultaneously.

## Key Files

### Created
- `javascripts/discourse/api-initializers/theme-setup.js` — mounts TavernBanner via `api.renderInOutlet("discovery-list-container-top", TavernBanner)`; guarded by `settings.show_homepage_banner`

### Modified
- `about.json` — added `theme_site_settings: { enable_welcome_banner: false }` to disable Discourse's native WelcomeBanner

### Deleted
- `javascripts/discourse/connectors/below-site-header/tavern-banner.hbs` — caused double render outside `#main-outlet-wrapper`, breaking SCSS context

## Decisions Made

None beyond plan spec. All changes matched the exact plan output.

## Self-Check: PASSED

- [x] `theme-setup.js` exists with `renderInOutlet("discovery-list-container-top", TavernBanner)`
- [x] `connectors/below-site-header/tavern-banner.hbs` deleted
- [x] `about.json` contains `"enable_welcome_banner": false` inside `theme_site_settings`
- [x] All changes committed
