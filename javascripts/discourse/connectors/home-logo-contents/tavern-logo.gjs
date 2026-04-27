import Component from "@glimmer/component";

export default class TavernLogo extends Component {
  get logoUrl() {
    return settings.logo || null;
  }

  <template>
    <div class="tavern-logo">
      {{#if this.logoUrl}}
        <img class="tavern-logo__image" src={{this.logoUrl}} alt={{@outletArgs.title}} />
      {{/if}}
      <div class="tavern-logo__text">
        <span class="tavern-logo__title">The Liberty Tavern</span>
        <span class="tavern-logo__tagline">Free Speech · Est. MDCCXCI</span>
      </div>
    </div>
  </template>
}
