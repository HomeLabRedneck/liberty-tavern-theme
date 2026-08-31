// Floating compose button for phones — the brass "+" circle from the mockup. Opens the new-topic
// composer (never a /new-topic link, per project rules). Mounted via renderInOutlet in
// theme-setup.js; position:fixed so its DOM location is irrelevant. Shown only on phones
// (common.scss §12 hides it ≥768px).
import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";

export default class TavernComposeFab extends Component {
  @service composer;

  @action
  newTopic() {
    this.composer.openNewTopic({});
  }

  <template>
    <button
      type="button"
      class="tavern-fab"
      title="Start a topic"
      aria-label="Start a topic"
      {{on "click" this.newTopic}}
    >+</button>
  </template>
}
