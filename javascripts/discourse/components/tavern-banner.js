import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { categoryBadgeHTML } from "discourse/helpers/category-link";
import { htmlSafe } from "@ember/template";

export default class TavernBanner extends Component {
  @service router;
  @service site;
  @service currentUser;
  @service composer;

  @tracked trending = [];
  @tracked badges = [];
  @tracked featured = null;
  @tracked loading = true;

  // Expose theme settings to the template via `this.settings`
  get settings() {
    return settings;
  }

  @action
  openNewTopic() {
    if (this.currentUser) {
      this.composer.openNewTopic({});
    } else {
      this.router.transitionTo("login");
    }
  }

  constructor() {
    super(...arguments);
    if (this.shouldShow) this.loadData();
  }

  get shouldShow() {
    if (!settings.show_homepage_banner) return false;
    const route = this.router.currentRouteName || "";
    return /^discovery\./.test(route);
  }

  get showBadges() {
    return settings.show_badges_card && this.badges.length > 0;
  }

  async loadData() {
    try {
      const period = settings.trending_period || "daily";
      // Try /top first; merge in /latest if we don't have enough topics
      // for both the featured slot AND a 3-up trending strip (need 4+).
      let topRes = await ajax(`/top.json?period=${period}`).catch(() => null);
      let topics = topRes?.topic_list?.topics || [];
      if (topics.length < 4) {
        const latestRes = await ajax("/latest.json").catch(() => null);
        const latest = latestRes?.topic_list?.topics || [];
        // Append any latest topics we don't already have
        const seen = new Set(topics.map((t) => t.id));
        for (const t of latest) {
          if (!seen.has(t.id)) {
            topics.push(t);
            seen.add(t.id);
          }
          if (topics.length >= 4) break;
        }
      }
      this.featured = topics[0] || null;
      this.trending = topics.slice(1, 4);

      // Recent badge grants — endpoint is /user_badges.json (underscore),
      // and it needs ?username= for per-user grants. For site-wide recent
      // grants we use the admin badge listing fallback: /badges.json gives
      // definitions; we then sample grant_count from there as a proxy.
      const badgeRes = await ajax("/badges.json").catch(() => null);
      if (badgeRes?.badges) {
        const tierMap = { 1: "common", 2: "rare", 3: "epic", 4: "legendary" };
        this.badges = badgeRes.badges
          .filter((b) => b.enabled && b.grant_count > 0)
          .sort((a, b) => b.grant_count - a.grant_count)
          .slice(0, 4)
          .map((b) => ({
            id: b.id,
            name: b.name,
            count: b.grant_count,
            tier: tierMap[b.badge_type_id] || "common",
            initial: (b.name || "?")[0],
          }));
      }
    } catch (e) {
      console.warn("Liberty Tavern banner: failed to load data", e);
    } finally {
      this.loading = false;
    }
  }

  categoryBadge = (catId) => {
    const cat = this.site.categories.findBy("id", catId);
    return cat ? htmlSafe(categoryBadgeHTML(cat, { allowUncategorized: true })) : "";
  };

  topicUrl = (topic) => `/t/${topic.slug}/${topic.id}`;
}
