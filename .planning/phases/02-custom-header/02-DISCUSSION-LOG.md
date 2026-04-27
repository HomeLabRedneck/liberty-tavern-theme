# Phase 2: Custom Header — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 02-custom-header
**Areas discussed:** Nav link routes, Sign In button, Logo component, Nav link mechanism

---

## Nav Link Routes

| Option | Description | Selected |
|--------|-------------|----------|
| Standard mapping | Trending=/hot, Rooms=/categories, Latest at the Bar=/latest, Top Shelf=/top | ✓ |
| Let me specify each one | User provides exact URL for each link | |

**User's choice:** Standard mapping
**Notes:** Follow-up on Trending vs Top Shelf: user confirmed Trending→/hot (recent spike), Top Shelf→/top (all-time best).

---

## Trending vs Top Shelf disambiguation

| Option | Description | Selected |
|--------|-------------|----------|
| Trending=/hot, Top Shelf=/top | Semantic split: activity spike vs. all-time best | ✓ |
| Trending=/top?period=daily, Top Shelf=/top | Period-param approach | |
| Trending=/top, Top Shelf=custom tag | Top Shelf as tag URL | |

**User's choice:** Trending=/hot, Top Shelf=/top

---

## Sign In Button

| Option | Description | Selected |
|--------|-------------|----------|
| Style existing login button via SCSS | Zero JS. Target .d-header .login-button | ✓ |
| Add custom button via api.headerIcons.add() | New JS, more control over position/label | |
| Use I18n to rename button text only | Override label via locales/en.yml, then style via SCSS | |

**User's choice:** Style existing login button via SCSS

---

## Logo Component

| Option | Description | Selected |
|--------|-------------|----------|
| Simple connector HBS | connectors/home-logo-contents/tavern-logo.hbs — img + title + tagline, no JS | ✓ |
| Glimmer component TavernLogo.js + .hbs | Full component with JS logic | |
| SCSS only — style Discourse native logo | Admin Logo setting upload, no custom markup | |

**User's choice:** Simple connector HBS

---

## Nav Link Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| I18n rename + top_menu setting | Rename native nav pills via locales/en.yml; add /hot to top_menu | ✓ |
| Custom injected link buttons | 4 plain link buttons via api.headerIcons.add() or outlet | |
| Hybrid: I18n for 3, custom for Trending | Rename Latest/Top/Categories; inject only Trending as custom button | |

**User's choice:** I18n rename + top_menu setting

---

## Claude's Discretion

- Correct I18n key paths for nav renames (`js.filters.*` or `js.nav.*`)
- Whether `top_menu` is overridable via `theme_site_settings` or requires an admin setting doc
- BEM class names for `.tavern-logo__*` elements

## Deferred Ideas

None.
