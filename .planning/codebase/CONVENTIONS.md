# Coding Conventions

**Analysis Date:** 2026-04-26

## Naming Patterns

**Files:**
- Glimmer component pairs use kebab-case: `tavern-banner.js` + `tavern-banner.hbs`
- API initializer files use kebab-case: `honored-patrons.js`
- Connector outlet directories mirror the outlet name exactly: `below-site-header/`
- SCSS file is a single monolithic file per context: `common/common.scss`

**CSS Classes:**
- Component classes use BEM with double underscore for elements: `.tavern-banner__grid`, `.tavern-banner__title`
- Modifier classes use double dash: `.tavern-banner__cta--ghost`, `.badge-icon--rare`
- Root component class matches the component name: `.tavern-banner`
- Discourse DOM targets are referenced by their real selectors (no wrapping): `.d-header`, `.sidebar-wrapper`, `.search-menu`

**JavaScript:**
- Class names are PascalCase: `TavernBanner`, `PatronLink`
- Variables and properties use camelCase: `groupName`, `patronsPromise`, `loadPatrons`
- Private/internal state is prefixed with underscore: `this._patrons`
- Settings accessed via the global `settings` object (Discourse convention), not imported
- I18n keys accessed via `I18n.t(themePrefix("..."))` (Discourse convention)

**Settings (settings.yml):**
- Keys use snake_case: `show_homepage_banner`, `honored_patrons_group`, `trending_period`
- Boolean toggles are prefixed with `show_` or `_enabled`: `show_homepage_banner`, `honored_patrons_enabled`

**Locales (locales/en.yml):**
- Keys are nested under the theme namespace: `liberty_tavern.banner.*`, `liberty_tavern.sidebar.*`
- All keys are snake_case: `project_of_the_night`, `honored_patrons`

## Code Style

**Formatting:**
- No formatter config file present (no `.prettierrc`, `.eslintrc`, `biome.json`)
- Indentation: 2 spaces throughout JavaScript and SCSS
- Single quotes for strings in JavaScript
- Template literals not used; string concatenation via template literals only where needed
- Trailing commas not used consistently

**SCSS:**
- Sections are delimited by numbered comment banners: `// ---- 1. Typography ---`
- BEM nesting is handled via `&` parent selector inside the root class block
- CSS custom properties defined on `:root` for reuse: `--font-display`, `--tavern-brass`
- Hard-coded hex values used alongside CSS variables; hex preferred inside `.d-header` and `.tavern-banner` blocks for preview compatibility
- `lighten()` and `darken()` SCSS functions used for hover states

**JavaScript:**
- ES module syntax (`import`/`export default`)
- Glimmer components use class-based syntax with `@tracked` decorators
- Services injected with `@service` decorator: `@service router`, `@service site`
- Arrow functions used for class fields that are callbacks: `categoryBadge = (catId) => ...`, `topicUrl = (topic) => ...`
- Regular methods used for getters (`get shouldShow()`, `get showBadges()`)
- `async/await` used for data fetching inside `loadData()`; `.then()/.catch()` chains used in the API initializer

## Import Organization

**Order (observed in `tavern-banner.js`):**
1. Glimmer/Ember framework imports (`@glimmer/component`, `@glimmer/tracking`, `@ember/service`)
2. Discourse lib imports (`discourse/lib/ajax`)
3. Discourse helper imports (`discourse/helpers/category-link`)
4. Ember template utilities (`@ember/template`)

**Path Aliases:**
- No custom path aliases; uses Discourse's standard module paths (`discourse/lib/...`, `discourse/helpers/...`, `@glimmer/...`, `@ember/...`)

## Error Handling

**Patterns:**
- Async failures are swallowed silently to preserve partial render: `ajax(...).catch(() => [])`, `ajax(...).catch(() => null)`
- Top-level `try/catch` in `loadData()` with a `console.warn` on failure; `finally` block always clears the loading state
- The API initializer uses `.catch(() => [])` on the patrons fetch so the sidebar renders empty rather than crashing
- No user-visible error states; component renders with whatever data loaded successfully
- Guard clause pattern used at the top of the initializer: `if (!settings.honored_patrons_enabled) return;`

## Logging

**Framework:** `console.warn` only

**Patterns:**
- One `console.warn` in `tavern-banner.js` for banner data load failures: `"Liberty Tavern banner: failed to load data"`
- All other failures are silently caught; no `console.error` or structured logging

## Comments

**When to Comment:**
- Section-level comments in SCSS explain the DOM target and scope: `// Restyles Discourse's real DOM. No layout overrides outside...`
- Inline comments explain non-obvious decisions: cache pattern for `patronsPromise`, the `sidebar:refresh` trigger workaround
- Workarounds are explained inline with a reason: `// Force the sidebar to re-render...`
- HTML files use comments to explain intentional empty files: `<!-- The connector at ... mounts the <TavernBanner /> component... -->`

**JSDoc/TSDoc:**
- Not used; this is a JavaScript (not TypeScript) codebase with no JSDoc annotations

## Function Design

**Size:** Functions are small and single-purpose. `loadData()` is the longest at ~45 lines and handles all three fetch operations in one method.

**Parameters:**
- Class constructors receive a single destructured object: `constructor({ user })`
- Callbacks receive a single argument: `(api) => { ... }`, `(users) => { ... }`

**Return Values:**
- Getters return primitives or arrays; no `undefined` returns in getters (fallback to `""`, `[]`, or `null`)
- `loadPatrons()` always returns a Promise that resolves to an array

## Module Design

**Exports:**
- One `export default` per file; no named exports

**Barrel Files:**
- Not used; Discourse theme structure does not use index re-exports

## Template Conventions (Handlebars)

**File:** `javascripts/discourse/components/tavern-banner.hbs`

- All data access goes through `this.*` prefix: `this.shouldShow`, `this.settings.banner_title`
- Conditional rendering uses `{{#if}}` / `{{#unless}}` blocks; no inline ternaries
- Iteration uses `{{#each ... as |alias|}}` with single-letter aliases for items: `|t|`, `|b|`
- Connector outlet files are minimal — only mount the component: `<TavernBanner />`
- Inline styles are used sparingly and only for one-off layout overrides within the template (e.g., the feature card title); all recurring styles belong in `common.scss`

---

*Convention analysis: 2026-04-26*
