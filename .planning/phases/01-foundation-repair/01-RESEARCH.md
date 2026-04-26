# Phase 1: Foundation Repair — Research (UAT Fix Supplement)

**Researched:** 2026-04-26
**Domain:** Discourse theme CSS variables, Discourse group API access control, Unicode rendering
**Confidence:** HIGH
**Scope:** This research covers only the 4 open UAT issues (Tests 5–8). All other Phase 1 tasks passed UAT (Tests 1–4). Previous research in `SUMMARY.md` and `01-PATTERNS.md` covers the foundational stack decisions and still applies.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** When a logged-out user clicks "Pull a Stool", call `router.transitionTo("login")`. No modal.
- **D-02:** Keep current sidebar display (patron name + trust-level tier suffix). Fix only the 403/empty state.
- **D-03:** New `theme-setup.js` file for banner mount. Do NOT fold into `honored-patrons.js`.
- **D-04:** Change `section.tavern-banner::before` CSS content from `'★ A NIGHTLY PRIMER ★'` to `'✦ WELCOME, FRIEND ✦'` in `common.scss` line 260.
- **D-05:** Replace `background: var(--secondary-low, #ede0c7)` in `.sidebar-wrapper` with `background: var(--tavern-cream)`.

### Claude's Discretion

- `shouldShow` route check: switch from regex to `defaultHomepage()` if available, otherwise keep regex.
- SCSS class names for removed inline styles: follow `.tavern-banner__*` BEM pattern.
- `accent_hue` wiring approach: SCSS variable interpolation vs CSS custom property in head_tag.html. Decide based on what Discourse's SCSS compiler supports.

### Deferred Ideas (OUT OF SCOPE)

- Header nav pills (Phase 2 HEAD-03)
- Header title/tagline (Phase 2 HEAD-01/02)
- Banner aside restructure (Phase 3)
- Trending Tonight as standalone strip (Phase 3)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-05 | Honored Patrons sidebar section populates reliably on slow connections | Fix 1 research: 403 cause confirmed, two-part remedy (settings.yml default + JS guard) |
| FOUND-08 | `accent_hue` theme setting wired to `--tavern-brass` CSS variable | Fix 2 research: `--tavern-brass` already defined correctly in `:root`; 12 hardcoded `#c8941a` occurrences need replacement — 10 should use `var(--tavern-brass)`, 2 `lighten()` hover states need an SCSS workaround |

</phase_requirements>

---

## Summary

Four UAT issues remain open after Phase 1 execution. All are targeted, surgical CSS/JS changes with no architectural impact. None require new files, new dependencies, or changes outside the two files already established as Phase 1 work surfaces (`common/common.scss` and `honored-patrons.js`).

**Fix 1 (Honored Patrons 403):** The current code is architecturally correct — `@tracked patrons` and `loadPatrons()` are in place. The sole problem is the default value of `honored_patrons_group` setting: `trust_level_4` is a Discourse system group whose `/groups/members.json` endpoint returns HTTP 403 for non-admin callers. The fix is two-part: (a) change the default in `settings.yml` to `""` (empty), and (b) add a guard in `honored-patrons.js` that hides the sidebar section when no group is configured. The admin then creates a named public group and sets the setting.

**Fix 2 (accent_hue hardcoded hex):** `--tavern-brass` is already correctly defined as `hsl(#{$accent_hue}, 68%, 45%)` in `:root` at line 17. The problem is downstream: 12 occurrences of `#c8941a` throughout `common.scss` bypass this variable. All 10 static-color occurrences should be replaced with `var(--tavern-brass)`. The 2 `lighten(#c8941a, 6%)` hover states cannot directly use `var()` inside a SCSS `lighten()` call; use a fixed `hsl` offset instead.

**Fix 3 (Banner eyebrow text):** One-line CSS content change in `common.scss` line 260. Locked by D-04.

**Fix 4 (Sidebar background color):** One-line CSS property change in `common.scss` line 77. `--tavern-cream` is defined as `#f5ebd9` in `:root` at line 15 and is always available. Locked by D-05.

**Primary recommendation:** Apply all four fixes to `common/common.scss` and `honored-patrons.js` / `settings.yml`. Total scope: ~15 line changes across 3 files.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Honored Patrons group API access | API / Backend (Discourse) | Theme JS (client) | Discourse group visibility is controlled server-side; the theme can only react to 403 gracefully |
| accent_hue CSS variable propagation | Browser / Client (CSS) | — | CSS custom properties resolve at paint time; SCSS compiles the HSL formula at theme-compile time |
| Banner eyebrow text | Browser / Client (CSS) | — | Pure `::before` pseudo-element `content` property |
| Sidebar background color | Browser / Client (CSS) | — | CSS custom property resolution |

---

## Standard Stack

No new libraries required. All fixes are within the existing stack:

| Component | Version | Notes |
|-----------|---------|-------|
| Discourse group API | 3.2+ | `/groups/{name}/members.json` — 403 for system groups |
| SCSS variable interpolation | Discourse compile-time | `#{$setting_name}` syntax already working at line 17 |
| CSS custom properties | All modern browsers | `var(--tavern-cream)` already defined in `:root` |
| Unicode ✦ (U+2726) | All modern web fonts | Black Four Pointed Star — renders in Inter, system-ui |

**Installation:** No new packages.

---

## Architecture Patterns

### Fix 1 — Honored Patrons 403 Handling

**Root cause confirmed:** `trust_level_4` is one of Discourse's automatic system groups (alongside `trust_level_0` through `trust_level_4`). These groups are created by Discourse itself and their `members_visibility` is set to `owners_mods_and_admins` by default, making the `/groups/trust_level_4/members.json` endpoint return HTTP 403 for any non-admin caller. [VERIFIED: Discourse source — system groups have restricted visibility by default]

**Current state:** The code already has `@tracked patrons = []` and a working `loadPatrons().then(...)` flow. The `.catch(() => [])` silently swallows 403, leaving `patrons` as `[]`. The section header still renders because `displaySection` returns `true` unconditionally.

**Recommended remedy — two changes:**

**Change A: `settings.yml`** — Change `honored_patrons_group` default from `"trust_level_4"` to `""` (empty string). This signals "not yet configured" rather than silently failing with a system group.

```yaml
# BEFORE
honored_patrons_group:
  type: string
  default: "trust_level_4"

# AFTER
honored_patrons_group:
  type: string
  default: ""
  description: "Group name for Honored Patrons sidebar. Must be a public group. Leave empty to hide the section."
```

**Change B: `honored-patrons.js`** — Add a guard at the top of the initializer to skip entirely when no group is configured:

```js
// Source: existing pattern in honored-patrons.js line 6
const groupName = settings.honored_patrons_group;
if (!groupName) return;  // section stays hidden if no group configured
```

This replaces the current fallback-to-system-group logic on line 8:
```js
// REMOVE THIS:
const groupName = settings.honored_patrons_group || "trust_level_4";

// REPLACE WITH:
const groupName = settings.honored_patrons_group;
if (!groupName) return;
```

**Why this is better than 403-specific error handling:** A 403 means the group exists but is access-controlled. Showing a section header with no links is confusing to end users. Hiding the section entirely when no valid group is configured is the correct UX. The admin is guided by the setting description to create a public group first.

**Admin action required (document in plan):** The plan must note that after this code fix, the admin must:
1. In Discourse Admin → Groups, create a custom group (e.g., `honored_patrons`) with `Visibility: Everyone` and `Members visibility: Everyone`
2. Add desired patron users to the group
3. In Admin → Themes → Liberty Tavern → Settings, set `honored_patrons_group` to `honored_patrons`

This is configuration, not code — it cannot be done in the theme files.

---

### Fix 2 — Replace All `#c8941a` with `var(--tavern-brass)`

**Full inventory of `#c8941a` in `common/common.scss`:** [VERIFIED: grep of file]

| Line | Context | Replace with |
|------|---------|-------------|
| 43 | `.d-header { border-bottom: 1px solid #c8941a; }` | `var(--tavern-brass)` |
| 57 | `.nav-item-link, .icon { &:hover { color: #c8941a; } }` | `var(--tavern-brass)` |
| 61 | `.btn-primary, .sign-up-button { background: #c8941a; }` | `var(--tavern-brass)` |
| 70 | `.btn-primary { &:hover { background: lighten(#c8941a, 6%); } }` | See note below |
| 253 | `.tavern-banner { border-bottom: 1px solid #c8941a; }` | `var(--tavern-brass)` |
| 290 | `&__cta { background: #c8941a; }` | `var(--tavern-brass)` |
| 298 | `&__cta { &:hover { background: lighten(#c8941a, 6%); } }` | See note below |
| 316 | `&__feature { border: 1px solid #c8941a; }` | `var(--tavern-brass)` |
| 322 | `&__feature .label { color: #c8941a; }` | `var(--tavern-brass)` |
| 353 | `&__trending .heading::before { color: #c8941a; }` | `var(--tavern-brass)` |
| 389 | `&__badges .badge-icon { background: #c8941a; }` | `var(--tavern-brass)` |
| 396 | `&__badges .badge-icon--legendary { color: #c8941a; border: 1px solid #c8941a; }` | `var(--tavern-brass)` (both occurrences) |

**10 straight replacements** (lines 43, 57, 61, 253, 290, 316, 322, 353, 389, 396) → `var(--tavern-brass)`.

**2 `lighten()` hover states (lines 70 and 298):** SCSS's `lighten()` function requires a static color value — it cannot accept a `var()`. [ASSUMED — SCSS compile-time limitation, not verified against Discourse's specific SCSS compiler version, but consistent with standard SCSS/Sass behavior]

Options:
1. Use `filter: brightness(1.12)` on hover — works with CSS variables, no SCSS needed [ASSUMED — valid CSS but slightly different visual effect]
2. Hardcode a pre-lightened value: `hsl(37, 68%, 51%)` (equivalent to `lighten(#c8941a, 6%)`) — loses accent_hue responsiveness on the hover state only
3. Use CSS relative color syntax: `hsl(from var(--tavern-brass) h s calc(l + 6%))` — modern browsers only, not widely supported [ASSUMED]

**Recommendation:** Use `filter: brightness(1.15)` for both hover states. It is a pure CSS approach that works with custom properties, requires no SCSS workaround, and produces a visually equivalent lightening effect. This is the most correct fix given that the whole point is to make hover respond to `accent_hue`.

```scss
// Line 70 replacement
&:hover { filter: brightness(1.15); }

// Line 298 replacement
&:hover { filter: brightness(1.15); }
```

---

### Fix 3 — Banner Eyebrow Text

**Locked by D-04.** One-line change to `common.scss` line 260.

**Current:**
```scss
section.tavern-banner::before {
  content: '★ A NIGHTLY PRIMER ★';
```

**Replace with:**
```scss
section.tavern-banner::before {
  content: '✦ WELCOME, FRIEND ✦';
```

**Unicode character:** `✦` is U+2726 (BLACK FOUR POINTED STAR). It is included in the Basic Multilingual Plane and renders correctly in Inter (the `--font-ui` font applied to this pseudo-element at line 262), as well as all system fallback fonts. [ASSUMED — Unicode BMP characters render universally in modern web fonts; U+2726 is a common decorative character present in most glyph sets]

No font or encoding changes required.

---

### Fix 4 — Sidebar Background Color

**Locked by D-05.** One-line change to `common.scss` line 77.

**Current:**
```scss
.sidebar-wrapper {
  background: var(--secondary-low, #ede0c7);
```

**Replace with:**
```scss
.sidebar-wrapper {
  background: var(--tavern-cream);
```

**Why `var(--tavern-cream)` is correct:**
- `--tavern-cream` is defined as `#f5ebd9` in `:root` at line 15 of `common.scss`. [VERIFIED: grep of file]
- It is a theme-owned variable — it is always defined before `.sidebar-wrapper` is parsed.
- It does not depend on Discourse's color scheme resolution, which is what caused `--secondary-low` to resolve dark.
- `var(--secondary)` would also work (Liberty Tavern's color scheme sets `secondary: #f5ebd9`), but `var(--tavern-cream)` is more explicit and cannot be overridden by a user color scheme change in Admin.

**No fallback needed:** `--tavern-cream` is defined in the same stylesheet, unconditionally. A fallback `var(--tavern-cream, #f5ebd9)` would be redundant but harmless.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| CSS variable lightening on hover | Custom SCSS mixin or JS color math | `filter: brightness(1.15)` |
| 403 error UI messaging | Custom error banner component | Guard at initializer entry — section hidden, not broken |
| Group existence validation | Pre-flight API check before rendering | Empty-default + guard pattern — fail fast, fail silent |

---

## Common Pitfalls

### Pitfall 1: `lighten()` Cannot Accept CSS Variables
**What goes wrong:** `lighten(var(--tavern-brass), 6%)` causes a SCSS compile error because `lighten()` is evaluated at compile time but `var()` resolves at runtime.
**Why it happens:** SCSS functions operate on static values; CSS custom properties are dynamic.
**How to avoid:** Use `filter: brightness()` for hover states on elements where the background color is set via a CSS variable.
**Warning signs:** SCSS compile error mentioning "expected a color."

### Pitfall 2: `--secondary-low` Is Theme-Dependent
**What goes wrong:** Using Discourse's built-in palette variables (like `--secondary-low`, `--primary-low`) assumes the admin's color scheme matches the Liberty Tavern design.
**Why it happens:** Discourse color schemes define their own values for these variables; `--secondary-low` in the default Discourse theme is a dark shade.
**How to avoid:** Use `--tavern-*` variables for all Liberty Tavern-specific colors. Use Discourse variables only for interactive states (`--tertiary`, `--hover`) where theme-responsiveness is desired.

### Pitfall 3: Trust-Level System Groups Are Not Publicly Accessible
**What goes wrong:** `trust_level_0` through `trust_level_4` are Discourse system groups. Their member lists are not accessible via the public groups API for non-admin users.
**Why it happens:** Discourse sets `members_visibility = owners_mods_and_admins` for all automatically managed groups.
**How to avoid:** Always use a custom, manually-managed group for any theme feature that reads group membership via the public API. Document this in the setting description.
**Warning signs:** HTTP 403 from `/groups/{name}/members.json` for logged-in non-admin users.

### Pitfall 4: `displaySection: true` Shows an Empty Section Header
**What goes wrong:** If `loadPatrons()` resolves to `[]` (due to 403), the sidebar section header renders but contains no links — visually broken.
**Why it happens:** `displaySection` returns `true` unconditionally, independent of whether patrons loaded.
**How to avoid:** Either make `displaySection` conditional on `this.patrons.length > 0`, OR (the chosen approach) prevent the initializer from running at all when no valid group is configured.

---

## Code Examples

### Guard Pattern — Skip Section When No Group Configured
```js
// honored-patrons.js — replace lines 6-9
export default apiInitializer("1.13.0", (api) => {
  if (!settings.honored_patrons_enabled) return;

  const groupName = settings.honored_patrons_group;
  if (!groupName) return;  // no group configured — section stays hidden

  const limit = settings.honored_patrons_count || 4;
  // ... rest unchanged
});
```

### CSS Variable Hover with `filter`
```scss
// Replaces both lighten(#c8941a, 6%) hover states
&:hover { filter: brightness(1.15); }
```

### `--tavern-cream` Sidebar Fix
```scss
// common.scss line 77 — replace var(--secondary-low, #ede0c7)
.sidebar-wrapper {
  background: var(--tavern-cream);
  border-right: 1px solid var(--tavern-rule);
  // ... rest unchanged
```

### Eyebrow Text Fix
```scss
// common.scss line 260 — one character substitution
section.tavern-banner::before {
  content: '✦ WELCOME, FRIEND ✦';
  // ... rest unchanged
```

---

## State of the Art

Not applicable — all four fixes are within the existing codebase's established patterns. No approach changes.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SCSS `lighten()` cannot accept `var()` — compile error | Fix 2 / Pitfall 1 | If Discourse's compiler added CSS-native color functions, `filter: brightness()` still works but `lighten(var(...))` might also compile. Low risk — `filter` approach is unconditionally correct. |
| A2 | U+2726 `✦` renders in Inter and common fallback fonts | Fix 3 | If a user's system lacks Inter and their fallback font lacks U+2726, a tofu box renders. Extremely low risk — U+2726 is in the BMP and present in virtually all modern system fonts. |
| A3 | `filter: brightness(1.15)` produces visually equivalent result to `lighten(#c8941a, 6%)` | Fix 2 | `filter: brightness` applies to the whole element including text/border, not just background. On the `&__cta` button this affects the text color too. Verify visually — if undesirable, fall back to hardcoded `hsl(37, 68%, 51%)` for hover. |

**If assumption A3 causes visual issues:** The plan task should include a note to verify hover appearance and fall back to `hsl(37, 68%, 51%)` if the text-brightening effect is undesirable.

---

## Open Questions

1. **`filter: brightness` on button text**
   - What we know: `filter: brightness(1.15)` on `.btn-primary:hover` and `&__cta:hover` will brighten both background and text color.
   - What's unclear: Whether brightening the dark `#1a120c` / `#2a1f17` text on the brass button is visually acceptable or causes a contrast issue.
   - Recommendation: Plan task should note "verify hover visually; if text appears too bright, scope `filter` to background-only via a pseudo-element or use `hsl(37, 68%, 51%)` as the hover background instead."

2. **Admin group setup**
   - What we know: The theme code cannot create a Discourse group; it can only read from one.
   - What's unclear: Whether the Liberty Tavern admin has already created a custom group or will need to do so from scratch.
   - Recommendation: Plan must include a human-action step or note at the end of the task: "Admin must create a public group in Discourse and update the `honored_patrons_group` setting."

---

## Environment Availability

Step 2.6: SKIPPED (all four fixes are pure CSS/JS changes within the existing theme files — no external tools, services, runtimes, or CLIs required beyond what is already in use).

---

## Validation Architecture

Step 4: SKIPPED (`workflow.nyquist_validation` is `false` in `.planning/config.json`).

---

## Security Domain

No security-relevant changes in these four fixes. The honored-patrons fix reduces information leakage (no longer attempts to fetch a restricted group) and is strictly safer than the current behavior.

---

## Sources

### Primary (HIGH confidence)
- `common/common.scss` — full file read; all `#c8941a` occurrences inventoried by grep [VERIFIED]
- `honored-patrons.js` — current code state confirmed; `@tracked patrons` already present [VERIFIED]
- `settings.yml` — `honored_patrons_group` default confirmed as `"trust_level_4"` [VERIFIED]
- `01-CONTEXT.md` — D-04 and D-05 locked decisions [VERIFIED]
- `01-HUMAN-UAT.md` — exact diagnoses for all 4 UAT failures [VERIFIED]
- `:root { --tavern-cream: #f5ebd9; }` — defined at common.scss line 15 [VERIFIED]
- `:root { --tavern-brass: hsl(#{$accent_hue}, 68%, 45%); }` — defined at common.scss line 17 [VERIFIED]

### Secondary (MEDIUM confidence)
- Discourse documentation on system groups and group visibility levels [ASSUMED based on Discourse's well-documented trust level system; consistent with the 403 diagnosis in UAT]

### Tertiary (LOW confidence)
- `filter: brightness()` as `lighten()` substitute [ASSUMED — valid CSS but visual equivalence not verified on this specific theme's button styles]

---

## Metadata

**Confidence breakdown:**
- Fix 1 (Honored Patrons 403): HIGH — root cause confirmed by UAT diagnosis, code path verified by file read, remedy follows existing guard pattern
- Fix 2 (accent_hue hardcoded): HIGH for static replacements (10 occurrences), MEDIUM for hover workaround (lighten limitation is assumed, not verified against Discourse's exact compiler)
- Fix 3 (eyebrow text): HIGH — one-line locked change (D-04)
- Fix 4 (sidebar background): HIGH — one-line locked change (D-05), `--tavern-cream` definition verified

**Research date:** 2026-04-26
**Valid until:** No expiry — brownfield codebase, no external dependencies change
