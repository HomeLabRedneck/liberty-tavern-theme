// Section heading for the topic-list discovery views (Trending / Latest at the Bar / Top Shelf).
// Mounted via api.renderInOutlet("discovery-list-container-top", ...) in theme-setup.js so it lands
// as a direct child of #list-area; common.scss §10 places it in the "heading" grid area above the
// list (col 1), with the rail spanning from the heading row down. Renders nothing on the Rooms
// (categories) view — that view has its own "The Rooms" heading (.category-boxes::before) and the
// full banner + trending strip.
import Component from "@glimmer/component";
import { service } from "@ember/service";

// route → heading copy. Module-scope map keyed by Discourse's discovery route names.
const HEADINGS = {
  "discovery.hot": { emoji: "🔥", title: "Trending", subtitle: "Ranked by activity tonight" },
  "discovery.latest": { emoji: "🍺", title: "Latest at the Bar", subtitle: "Most recent posts" },
  "discovery.top": { emoji: "★", title: "Top Shelf", subtitle: "Highest-rated this week" },
};

export default class TavernListHeading extends Component {
  @service router;

  get info() {
    return HEADINGS[this.router.currentRouteName] ?? null;
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
