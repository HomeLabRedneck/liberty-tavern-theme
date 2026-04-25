# Liberty Tavern — Discourse Theme

A tavern-inspired theme for Discourse: serif typography (Playfair Display + Spectral), a cream/oxblood/brass palette, a custom homepage banner with **live** trending topics and recent badges, and an **Honored Patrons** sidebar section sourced from a real Discourse group.

![preview](assets/logo.png)

---

## What's in the box

| Feature | How it works |
|---|---|
| Color scheme (light + dark) | `about.json` declares both palettes; admins pick one in **Admin → Customize → Colors** |
| Typography (Playfair / Spectral / Inter) | Loaded via `common/head_tag.html` → Google Fonts; restyled in `common/common.scss` |
| Header restyle | `common.scss` targets `.d-header`, the existing logo + sign-up button |
| Sidebar restyle (Topics / Rooms / Tags / Channels / DMs) | `common.scss` targets `.sidebar-wrapper` — uses Discourse's real DOM, no rewrites |
| **Search dropdown** restyle | `common.scss` targets `.search-menu` — Discourse's own dropdown is kept |
| **Honored Patrons** sidebar section | `javascripts/discourse/api-initializers/honored-patrons.js` registers a custom section via `api.addSidebarSection` and pulls real group members from `/groups/<name>/members.json` |
| **Pull up a chair** homepage banner | Mounted via the `below-site-header` plugin outlet by `connectors/below-site-header/tavern-banner.hbs` |
| **Live trending strip** | Component fetches `/top.json?period=daily` on mount, renders top 3 topics with category badges |
| **Live badges card** | Component fetches `/user-badges.json` and groups recent grants by badge |
| **Project of the Night** card | Top topic from `/top.json` rendered with reply / view / like counts |

All live-data behavior is driven by **theme settings** (Admin → Customize → Themes → Liberty Tavern → Settings):

- `show_homepage_banner` — toggle the banner
- `banner_title` / `banner_subtitle` — edit the headline copy
- `show_trending_strip` / `trending_period` — toggle and time-window the strip
- `show_badges_card` — toggle the badges card
- `accent_hue` — primary accent hue (0–360)
- `honored_patrons_enabled` — toggle the sidebar section
- `honored_patrons_group` — group name to source from (default `trust_level_4`)
- `honored_patrons_count` — how many to show

---

## Install (from Git)

1. Push this folder to a public GitHub repo, e.g. `your-org/liberty-tavern-theme`.
2. In Discourse: **Admin → Customize → Themes → Install → "From a git repository"**.
3. Paste the repo URL. Click **Install**.
4. Click **Set as default** (or **Make user-selectable** for opt-in).
5. Open **Settings** on the theme page to edit copy, accent hue, patron group, etc.
6. To pull updates later, click **Update** on the theme page.

If something breaks: visit `https://your.site.com/safe-mode` and disable the theme to restore Discourse defaults.

---

## File layout

```
liberty-tavern/
├── about.json                      # manifest + 2 color schemes
├── settings.yml                    # admin-editable settings
├── locales/en.yml                  # I18n strings
├── assets/
│   └── logo.png                    # tavern logo (used in header.html)
├── common/
│   ├── common.scss                 # all styling (header, sidebar, search-menu, topic-list, banner)
│   ├── head_tag.html               # Google Fonts <link>
│   └── after_header.html           # (intentionally empty — banner comes from the connector)
└── javascripts/discourse/
    ├── api-initializers/
    │   └── honored-patrons.js      # api.addSidebarSection — fetches real group members
    ├── components/
    │   ├── tavern-banner.js        # Glimmer component — fetches /top.json + /user-badges.json
    │   └── tavern-banner.hbs       # template
    └── connectors/
        └── below-site-header/
            └── tavern-banner.hbs   # plugin-outlet mount point
```

---

## Development notes

- **Discourse version**: tested against Discourse 3.2+. The sidebar API (`api.addSidebarSection`) requires 3.0+, and the `below-site-header` plugin outlet has been stable since 2.7.
- **Live data**: all `ajax()` calls are unauthenticated public endpoints (`/top.json`, `/user-badges.json`, `/groups/.../members.json`). No API key needed.
- **Failure mode**: if any fetch fails the banner still renders with whatever loaded; if the sidebar fetch fails the section silently shows zero links.
- **No external runtime deps**: only Google Fonts. Everything else uses Discourse's bundled Ember/Glimmer + helpers (`ajax`, `categoryBadgeHTML`, `service`, `tracked`).

---

## License

MIT — do whatever, just don't sue.
