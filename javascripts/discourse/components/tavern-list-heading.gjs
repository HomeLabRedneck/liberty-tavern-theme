// Section heading for the topic-list discovery views (Trending / Latest at the Bar / Top Shelf).
// Mounted via api.renderInOutlet("discovery-list-container-top", ...) in theme-setup.js so it lands
// as a direct child of #list-area; common.scss §10 places it in the "heading" grid area above the
// list (col 1), with the rail spanning from the heading row down. Renders nothing on the Rooms
// (categories) view — that view has its own "The Rooms" heading (.category-boxes::before) and the
// full banner + trending strip.
import Component from "@glimmer/component";
import { service } from "@ember/service";

// Top Shelf subtitle follows the ACTUAL period Discourse shows (it auto-selects the period by
// content volume, so it isn't always "this week"). Keyed by the topic list's for_period.
const TOP_PERIOD_SUBTITLE = {
  daily: "Highest-rated today",
  weekly: "Highest-rated this week",
  monthly: "Highest-rated this month",
  quarterly: "Highest-rated this quarter",
  yearly: "Highest-rated this year",
  all: "Highest-rated of all time",
};

export default class TavernListHeading extends Component {
  @service router;
  @service discovery;

  get info() {
    switch (this.router.currentRouteName) {
      case "discovery.hot":
        return { emoji: "🔥", title: "Trending", subtitle: "Ranked by activity tonight" };
      case "discovery.latest":
        return { emoji: "🍺", title: "Latest at the Bar", subtitle: "Most recent posts" };
      case "discovery.top": {
        const period = this.discovery?.currentTopicList?.for_period;
        return {
          emoji: "★",
          title: "Top Shelf",
          subtitle: TOP_PERIOD_SUBTITLE[period] ?? "Highest-rated",
        };
      }
      default:
        return null;
    }
  }

  <template>
    {{#if this.info}}
      <div class="tavern-list-heading">
        <span class="tavern-list-heading__emoji" aria-hidden="true">{{this.info.emoji}}</span>
        <h2 class="tavern-list-heading__title">{{this.info.title}}</h2>
        <span class="tavern-list-heading__subtitle">{{this.info.subtitle}}</span>
      </div>
    {{/if}}
  </template>
}
