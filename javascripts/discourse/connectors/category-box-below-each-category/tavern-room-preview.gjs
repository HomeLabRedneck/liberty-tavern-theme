// Connector outlet: category-box-below-each-category
// Confirmed from Discourse Meta deprecation notice (meta.discourse.org/t/327580)
// Discourse passes @outletArgs={{hash category=c}} — so this.args.category is the Category model.
// If category.latestTopicTitle is not available on this Discourse install,
// the {{#if}} guard suppresses the element and the card degrades to 03-04 state.
import Component from "@glimmer/component";

export default class TavernRoomPreview extends Component {
  get latestTitle() {
    // Try both camelCase and snake_case — Discourse serializer varies by version
    return (
      this.args.category?.latestTopicTitle ??
      this.args.category?.latest_topic_title ??
      null
    );
  }

  get categoryUrl() {
    return (
      this.args.category?.url ??
      `/c/${this.args.category?.slug ?? ""}/${this.args.category?.id ?? ""}`
    );
  }

  <template>
    {{#if this.latestTitle}}
      <div class="tavern-room-preview">
        <a href={{this.categoryUrl}} class="tavern-room-preview__link">
          <span class="tavern-room-preview__chevron" aria-hidden="true">▶</span>
          <span class="tavern-room-preview__title">{{this.latestTitle}}</span>
        </a>
      </div>
    {{/if}}
  </template>
}
