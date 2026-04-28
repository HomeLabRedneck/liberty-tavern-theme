import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class TavernNav extends Component {
  @service router;

  get links() {
    const current = this.router.currentRouteName || "";
    return [
      { label: "Trending",         path: "/hot",        active: current.startsWith("discovery.hot") },
      { label: "Rooms",            path: "/categories", active: current.startsWith("discovery.categories") },
      { label: "Latest at the Bar",path: "/latest",     active: current.startsWith("discovery.latest") },
      { label: "Top Shelf",        path: "/top",        active: current.startsWith("discovery.top") },
    ];
  }

  <template>
    <nav class="tavern-header-nav">
      {{#each this.links as |link|}}
        <a href={{link.path}} class="tavern-nav-link {{if link.active "active"}}">
          {{link.label}}
        </a>
      {{/each}}
    </nav>
  </template>
}
