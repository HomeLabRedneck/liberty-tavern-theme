# Liberty Tavern Theme

## What This Is

A custom Discourse forum theme for the Liberty Tavern community — a real, active forum for politics, philosophy, hobbies, and bourbon. The theme wraps Discourse's default UI in a tavern aesthetic: cream/oxblood/brass color palette, Playfair Display headings, a custom homepage banner with live stats, styled room cards, and a sidebar Honored Patrons section.

## Core Value

The homepage must look and function like the design target — custom header, styled banner with live stats, trending section, and room cards — because that is the entire point of having a custom theme.

## Requirements

### Validated

- ✓ Color scheme defined (Liberty Tavern light + dark) — `about.json`
- ✓ Google Fonts loaded (Playfair Display, Spectral, Inter) — `common/head_tag.html`
- ✓ SCSS framework applied across typography, sidebar, search, topic list, categories, buttons — `common/common.scss`
- ✓ Admin-editable theme settings (10 settings in `settings.yml`)
- ✓ Banner Glimmer component exists with API data fetching (trending, badges) — `tavern-banner.js`
- ✓ Honored Patrons sidebar section fetches from Discourse group API — `honored-patrons.js`

### Active

- [ ] Custom header renders correctly — logo, "The Liberty Tavern" title + tagline, nav links (Trending, Rooms, Latest at the Bar, Top Shelf), search button, Sign In button
- [ ] Homepage banner appears once, in the correct position (above page content), not duplicated
- [ ] Banner uses correct typography — Playfair Display headline, italic gold numbers in stats panel
- [ ] Stats panel shows live data — active users (Patrons Inside), total members, posts today, open rooms/categories
- [ ] Trending Tonight strip shows 3 hot topics with category label, title, author, reply count
- [ ] The Rooms section renders categories as styled cards with colored icon, description, topic/post counts
- [ ] Badges panel (right column) shows recent/popular badges as a grid
- [ ] House Rules panel (right column) shows the 4 house rules
- [ ] Honored Patrons sidebar section displays correctly with patron avatars and post counts
- [ ] "Pull a Stool" CTA button works (does not 404)
- [ ] Double Google Fonts load fixed (currently loads twice — `head_tag.html` + `@import` in SCSS)

### Out of Scope

- Mobile-specific layouts — focus is desktop; Discourse handles mobile responsively
- Internationalization / i18n fixes — English-only forum, not a priority
- Automated tests — no test infrastructure exists and Discourse theme tooling doesn't support it
- New features beyond Image 1 design — user explicitly scoped to match the design target only

## Context

**Current broken state (Image 2):**
- Banner content appears twice: once as unstyled plain text at top of page, once as styled component below a "Welcome back" section. Root cause is likely the `below-site-header` connector outlet position conflicting with Discourse's native homepage components.
- Custom header (logo + navigation) is completely absent — previous attempts were made and reverted (see git history: commits `721a715`, `677863f`, `dc931a8`).
- Stats panel numbers render as plain text, not italic gold as designed.

**Technical environment:**
- Discourse 3.2+ (sidebar API requires 3.0+; `below-site-header` outlet stable since 2.7)
- No local build tools — all JS dependencies (Ember, Glimmer) provided by Discourse host at runtime
- Theme installed via git URL or Admin → Customize → Themes
- All admin config through `settings.yml` settings panel — no hardcoded feature flags

**Known bugs from codebase map:**
- `/new-topic` CTA link returns 404 — Discourse doesn't accept that as a URL path
- `sidebar:refresh` is an undocumented event — patrons section may show empty on slow connections
- `accent_hue` setting defined but never consumed by CSS
- Inline styles in `tavern-banner.hbs` override SCSS (lines 34–36)

## Constraints

- **Platform**: Discourse theme system — no Node.js, no npm, no local build step; JS/CSS compiled by Discourse's asset pipeline
- **API**: All live data via unauthenticated public REST endpoints — no API key available
- **Compatibility**: Must work with Discourse 3.2+; avoid private/undocumented APIs that change between versions
- **Deployment**: Changes go live by pushing to git repo — no CI/CD, no staging environment

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use Glimmer component for banner (not HTML injection) | HTML injection approach was attempted and reverted as broken; component approach is more maintainable | — Pending |
| Mount banner via `below-site-header` outlet | Standard Discourse outlet for above-content injections | ⚠️ Revisit — current positioning causes duplication with native homepage components |
| No local fonts — use Google Fonts CDN | Simplest path; Discourse host handles no font serving | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-26 after initialization*
