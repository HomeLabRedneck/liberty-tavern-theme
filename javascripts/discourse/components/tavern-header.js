import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class TavernHeader extends Component {
  @service site;

  get siteTitle() {
    return this.site.title || "The Liberty Tavern";
  }

  get siteTagline() {
    return this.site.description || "Free Speech · Est. MDCCXCI";
  }

  get logoUrl() {
    return this.site.logoUrl;
  }
}
