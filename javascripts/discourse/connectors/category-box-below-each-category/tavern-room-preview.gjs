// Connector outlet: category-box-below-each-category
// Discourse passes @outletArgs={{hash category=c}} — so this.args.category is the Category model.
// Renders the topic/post count block for each room card (ROOM-03).
// topic_count and post_count are always present on the Category model, so no {{#if}} guard
// is needed — every card gets its stats. CSS (§6b) absolutely-positions this block top-right.
import Component from "@glimmer/component";

export default class TavernRoomPreview extends Component {
  get category() {
    return this.args.category ?? this.args.outletArgs?.category;
  }

  get topics() {
    return this.category?.topic_count ?? 0;
  }

  get posts() {
    return this.category?.post_count ?? 0;
  }

  <template>
    <div class="tavern-room-preview">
      <div class="tavern-room-preview__stat">
        <span class="tavern-room-preview__num">{{this.topics}}</span>
        <span class="tavern-room-preview__lbl">Topics</span>
      </div>
      <div class="tavern-room-preview__stat">
        <span class="tavern-room-preview__num">{{this.posts}}</span>
        <span class="tavern-room-preview__lbl">Posts</span>
      </div>
    </div>
  </template>
}
