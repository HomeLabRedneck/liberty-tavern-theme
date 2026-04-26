# Liberty Tavern Theme — Project Guide

## What This Is

A custom Discourse forum theme for the Liberty Tavern community. Goal: make the forum match the Image 1 design target — custom header, homepage banner with live stats, trending section, category room cards, right-column badges + house rules, Honored Patrons sidebar.

## GSD Workflow

Planning docs live in `.planning/`. Read them before making changes.

**Key files:**
- `.planning/PROJECT.md` — project context, requirements, key decisions
- `.planning/ROADMAP.md` — 4 phases with success criteria
- `.planning/REQUIREMENTS.md` — 26 v1 requirements with REQ-IDs
- `.planning/research/SUMMARY.md` — Discourse API findings, outlet names, pitfall fixes
- `.planning/STATE.md` — current phase and status

**Workflow commands:**
- `/gsd-plan-phase N` — plan a phase before executing
- `/gsd-execute-phase N` — execute a planned phase
- `/gsd-progress` — check current status

## Architecture

**Tech stack:** Discourse 3.2+, Glimmer components, SCSS, no local build tools.

**Key files:**
- `common/common.scss` — all SCSS overrides (target Discourse's real DOM selectors)
- `common/head_tag.html` — Google Fonts `<link>` tags (do NOT duplicate in scss)
- `about.json` — theme manifest + color schemes + `theme_site_settings`
- `settings.yml` — admin-editable theme settings
- `javascripts/discourse/components/tavern-banner.js` + `.hbs` — homepage banner
- `javascripts/discourse/api-initializers/honored-patrons.js` — sidebar section
- `javascripts/discourse/connectors/` — plugin outlet mounts

## Critical Rules

1. **No `common/header.html`** — HTML injection in the header was tried and reverted 3 times. Use `home-logo-contents` outlet + `api.headerIcons.add()` + SCSS instead.
2. **No `appEvents.trigger("sidebar:refresh")`** — that event does not exist in Discourse. Use `@tracked` for reactive sidebar data.
3. **No `@import` for Google Fonts in SCSS** — fonts already loaded via `<link>` in `head_tag.html`. Adding `@import` causes double load.
4. **No inline `style="..."` in HBS templates** — they block CSS overrides. Put everything in `common.scss`.
5. **No `/new-topic` links** — that URL 404s. Use `this.composer.openNewTopic()` from the `composer` Ember service.
6. **Banner outlet:** Use `discovery-list-container-top` (not `below-site-header`). The `below-site-header` outlet renders outside `#main-outlet-wrapper` and breaks SCSS context.

## Discourse API Quick Reference

**Outlets (where to inject):**
- `discovery-list-container-top` — top of homepage content (above topic list)
- `home-logo-contents` — replaces the logo area in `.d-header`
- `after-main-outlet` — after the main outlet (for right-column layout)

**Header API:**
```js
api.headerIcons.add("name", Component, { before: "search" });
```

**New topic:**
```js
@service composer;
this.composer.openNewTopic({ categoryId, title, body });
```

**Stats endpoint:** `/about.json` → `about.stats` → `users_count`, `posts_last_day`, `active_users_last_day`
Categories count from `about.categories.length`.

**Sidebar reactivity:**
```js
@tracked patrons = [];
// later:
this.patrons = loadedUsers; // Glimmer re-renders automatically
```

## Color Palette

- Cream background: `#f5ebd9` / CSS var `--secondary`
- Oxblood accent: `#7a1f1f` / CSS var `--tertiary`
- Brass highlight: `#c8941a` → wired via `accent_hue` setting to `--tavern-brass`
- Dark banner bg: `#1a120c`

## Phase Status

See `.planning/STATE.md` for current phase. Run `/gsd-progress` to check.

**Phase 1** (Foundation Repair) is next. Start with `/gsd-plan-phase 1`.
