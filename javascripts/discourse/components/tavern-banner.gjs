import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
import Category from "discourse/models/category";

function timeAgo(isoString) {
  if (!isoString) return "";
  const diff = Math.floor((Date.now() - new Date(isoString).getTime()) / 1000);
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  return `${Math.floor(diff / 86400)}d`;
}

const toItem = (t) => {
  const cat = Category.findById(t.category_id);
  return {
    id: t.id,
    title: htmlSafe(t.fancy_title ?? t.title ?? ""),
    url: `/t/${t.slug}/${t.id}`,
    postsCount: t.posts_count,
    categoryName: cat?.name ?? "",
    author: t.last_poster_username ?? "",
    bumpedAt: t.bumped_at ?? null,
  };
};

export default class TavernBanner extends Component {
  @service router;
  @service currentUser;
  @service composer;

  @tracked trending = [];
  @tracked stats = null;
  @tracked loading = true;

  get settings() {
    return settings;
  }

  get shouldShow() {
    if (!settings.show_homepage_banner) return false;
    const route = this.router.currentRouteName || "";
    return /^discovery\./.test(route);
  }

  get statRows() {
    return [
      { label: "Patrons Inside", value: this.stats?.patronsInside ?? "—" },
      { label: "Members",        value: this.stats?.members        ?? "—" },
      { label: "Posts Today",    value: this.stats?.postsToday     ?? "—" },
      { label: "Open Rooms",     value: this.stats?.openRooms      ?? "—" },
    ];
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
      const [topRes, aboutRes] = await Promise.all([
        ajax(`/top.json?period=${period}`).catch(() => null),
        ajax("/about.json").catch(() => null),
      ]);

      // Stats from /about.json
      const s = aboutRes?.about?.stats ?? {};
      this.stats = {
        patronsInside: s.active_users_last_day ?? "—",
        members: s.users_count ?? "—",
        postsToday: s.posts_last_day ?? "—",
        openRooms: aboutRes?.about?.categories?.length ?? "—",
      };

      // Trending from /top.json with /latest.json fallback
      let raw = topRes?.topic_list?.topics || [];
      if (raw.length < 3) {
        const latestRes = await ajax("/latest.json").catch(() => null);
        const latest = latestRes?.topic_list?.topics || [];
        const seen = new Set(raw.map((t) => t.id));
        for (const t of latest) {
          if (!seen.has(t.id)) { raw.push(t); seen.add(t.id); }
          if (raw.length >= 3) break;
        }
      }
      // slice starts at 0 (not 1) because featured no longer consumes raw[0]
      this.trending = raw.slice(0, 3).map(toItem);
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
