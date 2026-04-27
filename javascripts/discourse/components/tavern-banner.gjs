import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";

export default class TavernBanner extends Component {
  @service router;
  @service currentUser;
  @service composer;

  @tracked trending = [];
  @tracked featured = null;
  @tracked badges = [];
  @tracked loading = true;

  get settings() {
    return settings;
  }

  get shouldShow() {
    if (!settings.show_homepage_banner) return false;
    const route = this.router.currentRouteName || "";
    return /^discovery\./.test(route);
  }

  get showBadges() {
    return settings.show_badges_card && this.badges.length > 0;
  }

  constructor() {
    super(...arguments);
    if (settings.show_homepage_banner) this.loadData();
  }

  @action
  openNewTopic() {
    if (this.currentUser) {
      this.composer.openNewTopic({});
    } else {
      this.router.transitionTo("login");
    }
  }

  async loadData() {
    try {
      const period = settings.trending_period || "daily";
      let topRes = await ajax(`/top.json?period=${period}`).catch(() => null);
      let raw = topRes?.topic_list?.topics || [];
      if (raw.length < 4) {
        const latestRes = await ajax("/latest.json").catch(() => null);
        const latest = latestRes?.topic_list?.topics || [];
        const seen = new Set(raw.map((t) => t.id));
        for (const t of latest) {
          if (!seen.has(t.id)) { raw.push(t); seen.add(t.id); }
          if (raw.length >= 4) break;
        }
      }

      const toItem = (t) => ({
        id: t.id,
        title: htmlSafe(t.fancy_title ?? t.title ?? ""),
        url: `/t/${t.slug}/${t.id}`,
        postsCount: t.posts_count,
        views: t.views,
        likeCount: t.like_count,
      });

      this.featured = raw[0] ? toItem(raw[0]) : null;
      this.trending = raw.slice(1, 4).map(toItem);

      const badgeRes = await ajax("/badges.json").catch(() => null);
      if (badgeRes?.badges) {
        const tierMap = { 1: "common", 2: "rare", 3: "epic", 4: "legendary" };
        this.badges = badgeRes.badges
          .filter((b) => b.enabled && b.grant_count > 0)
          .sort((a, b) => b.grant_count - a.grant_count)
          .slice(0, 4)
          .map((b) => ({
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

  <template>
    {{#if this.shouldShow}}
      <section class="tavern-banner">
        <div class="tavern-banner__grid">
          <div class="tavern-banner__main">
            <h1 class="tavern-banner__title">{{this.settings.banner_title}}</h1>
            <p class="tavern-banner__subtitle">{{this.settings.banner_subtitle}}</p>
            <button type="button" class="tavern-banner__cta" {{on "click" this.openNewTopic}}>Pull a stool</button>
            <a href="/faq" class="tavern-banner__cta tavern-banner__cta--ghost">Read the House Rules</a>

            {{#if this.settings.show_trending_strip}}
              <div class="tavern-banner__trending">
                <div class="heading">Trending Tonight</div>
                {{#unless this.loading}}
                  <div class="items">
                    {{#each this.trending as |t|}}
                      <div class="item">
                        <a href={{t.url}}>{{t.title}}</a>
                        <div class="meta">{{t.postsCount}} replies · {{t.views}} views</div>
                      </div>
                    {{/each}}
                  </div>
                {{/unless}}
              </div>
            {{/if}}
          </div>

          <aside class="tavern-banner__aside">
            {{#if this.featured}}
              <div class="tavern-banner__feature">
                <div class="label">Project of the Night</div>
                <a href={{this.featured.url}} class="tavern-banner__feature-link">
                  <h3 class="tavern-banner__feature-title">{{this.featured.title}}</h3>
                </a>
                <div class="stats">
                  <span class="stat-label">replies</span>
                  <span class="stat-value">{{this.featured.postsCount}}</span>
                  <span class="stat-label">views</span>
                  <span class="stat-value">{{this.featured.views}}</span>
                  <span class="stat-label">likes</span>
                  <span class="stat-value">{{this.featured.likeCount}}</span>
                </div>
              </div>
            {{/if}}

            {{#if this.showBadges}}
              <div class="tavern-banner__badges">
                <div class="heading">Recent Badges Awarded</div>
                {{#each this.badges as |b|}}
                  <div class="badge-row">
                    <span class="badge-icon badge-icon--{{b.tier}}">{{b.initial}}</span>
                    <span class="badge-name">{{b.name}}</span>
                    <span class="badge-count">×{{b.count}}</span>
                  </div>
                {{/each}}
              </div>
            {{/if}}
          </aside>
        </div>
      </section>
    {{/if}}
  </template>
}
