import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { categoryBadgeHTML } from "discourse/helpers/category-link";
import { htmlSafe } from "@ember/template";
import { hbs } from "ember-cli-htmlbars";
import RouteTemplate from "ember-route-template";

export default class TavernBanner extends Component {
  @service router;
  @service site;

  @tracked trending = [];
  @tracked badges = [];
  @tracked featured = null;
  @tracked loading = true;

  constructor() {
    super(...arguments);
    if (this.shouldShow) this.loadData();
  }

  get shouldShow() {
    if (!settings.show_homepage_banner) return false;
    const route = this.router.currentRouteName || "";
    // Show on /latest, /top, /new, /unread, /categories
    return /^discovery\.(latest|top|new|unread|categories|hot)$/.test(route);
  }

  async loadData() {
    try {
      const period = settings.trending_period || "daily";
      const [topRes, badgeRes] = await Promise.all([
        ajax(`/top.json?period=${period}`),
        ajax(`/user-badges.json?offset=0&limit=4`).catch(() => null),
      ]);

      const topics = topRes?.topic_list?.topics || [];
      this.featured = topics[0] || null;
      this.trending = topics.slice(1, 4);

      if (badgeRes?.user_badges) {
        // Group recent badge grants by badge id
        const seen = new Map();
        for (const ub of badgeRes.user_badges) {
          if (!seen.has(ub.badge_id)) seen.set(ub.badge_id, { badge_id: ub.badge_id, count: 0 });
          seen.get(ub.badge_id).count += 1;
        }
        const badgeDefs = (badgeRes.badges || []).reduce((m, b) => (m[b.id] = b, m), {});
        this.badges = [...seen.values()]
          .map((b) => ({
            id: b.badge_id,
            name: badgeDefs[b.badge_id]?.name || "Badge",
            count: b.count,
            tier: ["common","rare","rare","epic","legendary"][badgeDefs[b.badge_id]?.badge_type_id] || "common",
            initial: (badgeDefs[b.badge_id]?.name || "?")[0],
          }))
          .slice(0, 4);
      }
    } catch (e) {
      // Fail quietly; banner just renders without live data
      console.warn("Liberty Tavern banner: failed to load data", e);
    } finally {
      this.loading = false;
    }
  }

  categoryBadge(catId) {
    const cat = this.site.categories.findBy("id", catId);
    return cat ? htmlSafe(categoryBadgeHTML(cat, { allowUncategorized: true })) : "";
  }

  topicUrl(topic) {
    return `/t/${topic.slug}/${topic.id}`;
  }
}
