# Testing Patterns

**Analysis Date:** 2026-04-26

## Test Framework

**Runner:** None detected

No test runner, test framework, or test configuration files are present in this codebase. There are no `jest.config.*`, `vitest.config.*`, `qunit.config.*`, or equivalent files.

**Config:** Not applicable

**Run Commands:**
```bash
# No test commands configured
```

## Test File Organization

**Location:** No test files exist in this codebase.

A search across all directories finds no `*.test.*` or `*.spec.*` files.

**Named test directories:** None (`tests/`, `__tests__/`) — not present.

## Current Test Coverage

**Coverage:** 0% — no tests of any kind exist.

**What is untested:**
- `javascripts/discourse/components/tavern-banner.js` — all component logic
- `javascripts/discourse/api-initializers/honored-patrons.js` — all sidebar initializer logic
- `common/common.scss` — all visual styling
- `settings.yml` — all setting defaults and constraints

## Discourse Theme Testing Context

Discourse themes do not have a built-in unit test harness equivalent to a standard Ember app. Testing options for Discourse themes are:

1. **Discourse Theme Creator** — Browser-based live preview at `https://theme-creator.discourse.org`
2. **Local Discourse install** — Install theme via Admin → Customize → Themes → Install from git
3. **Safe mode** — `https://your-site.com/safe-mode` to disable the theme and compare
4. **Ember component tests** — Discourse core supports QUnit + `@ember/test-helpers` for plugins; themes can use this infrastructure but it requires a full Discourse dev environment

No testing infrastructure has been set up for this theme.

## Recommended Testing Approach

If tests are added in the future, the Discourse testing conventions would apply:

**Framework:**
- QUnit (Discourse's standard test runner)
- `@ember/test-helpers` for component rendering
- `ember-qunit` for Glimmer component tests

**Test file location convention:**
```
javascripts/discourse/tests/
├── unit/
│   └── honored-patrons-test.js
└── integration/
    └── components/
        └── tavern-banner-test.js
```

**Test structure (Discourse pattern):**
```javascript
import { module, test } from "qunit";
import { setupRenderingTest } from "ember-qunit";
import { render } from "@ember/test-helpers";
import { hbs } from "ember-cli-htmlbars";

module("Integration | Component | tavern-banner", function (hooks) {
  setupRenderingTest(hooks);

  test("renders when on discovery route", async function (assert) {
    await render(hbs`<TavernBanner />`);
    assert.dom(".tavern-banner").exists();
  });
});
```

**Mocking ajax calls:**
```javascript
import { ajax } from "discourse/lib/ajax";
import sinon from "sinon";

// Stub ajax to return fixture data
sinon.stub(ajax).returns(Promise.resolve({ topic_list: { topics: [] } }));
```

## Key Logic to Test (if tests are added)

**`tavern-banner.js`:**
- `shouldShow` returns `false` when `settings.show_homepage_banner` is false
- `shouldShow` returns `false` on non-discovery routes
- `loadData()` populates `this.featured` with `topics[0]`
- `loadData()` populates `this.trending` with `topics.slice(1, 4)`
- `loadData()` falls back to `/latest.json` when `/top.json` returns fewer than 4 topics
- `loadData()` sets `this.loading = false` in all cases (success and failure)
- `showBadges` returns `false` when `settings.show_badges_card` is false
- `categoryBadge()` returns `""` for unknown category IDs

**`honored-patrons.js`:**
- Initializer returns early when `settings.honored_patrons_enabled` is false
- `loadPatrons()` caches the promise (only one `ajax()` call per page load)
- `loadPatrons()` returns `[]` when the ajax call fails
- `PatronLink.prefixValue` replaces `{size}` in `avatar_template`
- `PatronLink.suffixValue` maps trust levels 0–4 to correct tier labels

---

*Testing analysis: 2026-04-26*
