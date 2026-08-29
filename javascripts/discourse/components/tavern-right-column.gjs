// Homepage right-column rail: Badges panel + House Rules panel.
// Mounted via api.renderInOutlet("discovery-list-container-top", ...) in theme-setup.js
// (the same outlet the banner uses) so the rail lands as a direct child of #list-area.
// common.scss §10 grids #list-area so the banner + trending span both columns while the
// list falls into column 1 and this rail into column 2 (verified live in plan 04-02).
// Constrained to the four homepage discovery views by:
//   1. this.shouldShow route gate (/^discovery\./) — same gate the banner uses.
//   2. SCSS body-class scoping (body.navigation-categories / body.navigation-topics).
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

// Maps badge_type_id -> hexagon tier modifier class (module-scope functions are in GJS
// template scope by design, same pattern as timeAgo in tavern-banner.gjs).
// 1 -> gold (brass), 2 -> silver (#808281), 3 -> bronze (#8C6238); default gold.
function tierClass(typeId) {
  if (typeId === 2) return "tavern-badges__hex--silver";
  if (typeId === 3) return "tavern-badges__hex--bronze";
  return "tavern-badges__hex--gold";
}

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
    if (settings.show_right_column) {
      this.loadBadges();
    }
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
                    <span class="tavern-badges__hex {{tierClass b.typeId}}">
                      {{#if b.imageUrl}}
                        <img src={{b.imageUrl}} alt="" width="20" height="20" />
                      {{else}}
                        <span>{{b.icon}}</span>
                      {{/if}}
                    </span>
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
