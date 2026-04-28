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
          </div>

          <aside class="tavern-banner__aside">
            <div class="tavern-banner__stats">
              <div class="label">TONIGHT AT THE HOUSE</div>
              {{#each this.statRows as |row|}}
                <div class="tavern-banner__stat-row">
                  <span class="tavern-banner__stat-label">{{row.label}}</span>
                  {{#unless this.loading}}
                    <span class="tavern-banner__stat-num">{{row.value}}</span>
                  {{else}}
                    <span class="tavern-banner__stat-num tavern-banner__stat-num--loading">—</span>
                  {{/unless}}
                </div>
              {{/each}}
            </div>
          </aside>
        </div>
      </section>

      {{#if this.settings.show_trending_strip}}
        <div class="tavern-trending">
          <div class="tavern-trending__header">
            <span class="tavern-trending__heading">🔥 TRENDING TONIGHT</span>
            <a href="/hot" class="tavern-trending__all">ALL HOT THREADS →</a>
          </div>
          {{#unless this.loading}}
            <div class="tavern-trending__items">
              {{#each this.trending as |t|}}
                <div class="tavern-trending__item">
                  <span class="tavern-trending__cat">{{t.categoryName}}</span>
                  <a href={{t.url}} class="tavern-trending__title">{{t.title}}</a>
                  <div class="tavern-trending__meta">
                    {{t.author}} · {{t.postsCount}} replies · {{timeAgo t.bumpedAt}}
                  </div>
                </div>
              {{/each}}
            </div>
          {{/unless}}
        </div>
      {{/if}}
    {{/if}}
  </template>
}
