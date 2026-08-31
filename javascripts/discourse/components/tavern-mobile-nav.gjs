// Phone section-nav tabs (Rooms / Latest / Hot / Top). Discourse collapses its mobile
// navigation into a single dropdown, so the mockup's tab row is rendered here instead.
// Mounted via api.renderInOutlet("discovery-list-container-top", ...) in theme-setup.js and
// shown only on phones (common.scss §12 hides it ≥768px). Plain anchors — Discourse's router
// intercepts internal links for SPA navigation.
import Component from "@glimmer/component";
import { service } from "@ember/service";

const TABS = [
  { label: "Rooms", route: "discovery.categories", href: "/categories" },
  { label: "Latest", route: "discovery.latest", href: "/latest" },
  { label: "Hot", route: "discovery.hot", href: "/hot" },
  { label: "Top", route: "discovery.top", href: "/top" },
];

export default class TavernMobileNav extends Component {
  @service router;

  get tabs() {
    const current = this.router.currentRouteName || "";
    return TABS.map((t) => ({ ...t, active: current === t.route }));
  }

  <template>
    <nav class="tavern-mnav">
      {{#each this.tabs as |t|}}
        <a
          href={{t.href}}
          class="tavern-mnav__tab {{if t.active 'is-active'}}"
        >{{t.label}}</a>
      {{/each}}
    </nav>
  </template>
}
