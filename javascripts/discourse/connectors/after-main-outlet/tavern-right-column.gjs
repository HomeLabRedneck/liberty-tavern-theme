// Connector outlet: after-main-outlet (a GLOBAL Discourse outlet — fires on every route).
// The rail is constrained to the four homepage discovery views (Rooms / Trending /
// Latest at the Bar / Top Shelf) by TWO gates working together:
//   1. this.shouldShow route gate (/^discovery\./ on router.currentRouteName) — same gate
//      the banner uses; keeps the component from rendering on topic pages / other routes.
//   2. SCSS body-class scoping (body.navigation-categories / body.navigation-topics) —
//      constrains the grid override + rail visibility to the discovery wrapper.
//
// MOUNT STRATEGY (PRIMARY): this connector auto-mounts at after-main-outlet, which Discourse
// renders as the last child inside #main-outlet. common.scss §10 grids #main-outlet so the
// list-container falls into column 1 and this rail into column 2, while the full-width banner
// outlet + .tavern-trending span both tracks (grid-column: 1 / -1).
// FALLBACK (if live DevTools in plan 04-02 shows after-main-outlet renders OUTSIDE #main-outlet
// and cannot be a grid sibling of the banner+list): mount instead via
// api.renderInOutlet(<inside-#main-outlet discovery outlet>, TavernRightColumn) in theme-setup.js
// (guarded by settings.show_right_column) and grid that inner wrapper. The 280px rail / 32px
// gutter / 1160px breakpoint contract holds either way.
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

export default class TavernRightColumn extends Component {
  @service router;

  @tracked badges = [];
  @tracked loading = true;

  get settings() {
    return settings;
  }

  get shouldShow() {
    if (!settings.show_right_column) return false;
    const route = this.router.currentRouteName || "";
    return /^discovery\./.test(route);
  }

  get houseRules() {
    return (settings.house_rules || "")
      .split("|")
      .map((s) => s.trim())
      .filter(Boolean);
  }

  get hasBadges() {
    return this.badges.length > 0;
  }

  constructor() {
    super(...arguments);
    if (settings.show_right_column) this.loadBadges();
  }

  async loadBadges() {
    try {
      const res = await ajax("/badges.json").catch(() => null);
      const raw = res?.badges ?? [];
      // Sort a COPY by grant_count descending, take the top 4.
      this.badges = [...raw]
        .sort((a, b) => (b.grant_count ?? 0) - (a.grant_count ?? 0))
        .slice(0, 4)
        .map((b) => ({
          name: b.name,
          count: b.grant_count,
          typeId: b.badge_type_id,
          icon: b.icon,
          imageUrl: b.image_url,
        }));
    } catch (e) {
      console.warn("Liberty Tavern right column: failed to load badges", e);
    } finally {
      this.loading = false;
    }
  }

  <template>
    {{#if this.shouldShow}}
      <aside class="tavern-right-column">
        {{#if this.hasBadges}}
          {{#unless this.loading}}
            <div class="tavern-badges">
              <h3 class="tavern-badges__header">Badges</h3>
              <div class="tavern-badges__grid">
                {{#each this.badges as |b|}}
                  <div class="tavern-badges__tile">
                    <span class="tavern-badges__name">{{b.name}}</span>
                    <span class="tavern-badges__count">{{b.count}} EARNED</span>
                  </div>
                {{/each}}
              </div>
            </div>
          {{/unless}}
        {{/if}}

        <div class="tavern-house-rules">
          <div class="tavern-house-rules__eyebrow">HOUSE RULES</div>
          <ol class="tavern-house-rules__list">
            {{#each this.houseRules as |rule|}}
              <li>{{rule}}</li>
            {{/each}}
          </ol>
        </div>
      </aside>
    {{/if}}
  </template>
}
