import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";

export default apiInitializer("1.13.0", (api) => {
  if (!settings.honored_patrons_enabled) return;

  const groupName = settings.honored_patrons_group;
  if (!groupName) return;
  const limit = settings.honored_patrons_count || 4;

  // Cache of group members fetched once per page load.
  let patronsPromise = null;
  function loadPatrons() {
    if (patronsPromise) return patronsPromise;
    patronsPromise = ajax(`/groups/${groupName}/members.json?limit=${limit}&order=added_at&asc=false`)
      .then((r) => r.members || [])
      .catch(() => []);
    return patronsPromise;
  }

  api.addSidebarSection((BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {
    class PatronLink extends BaseCustomSidebarSectionLink {
      constructor({ user }) {
        super();
        this.user = user;
      }
      get name() { return `patron-${this.user.username}`; }
      get route() { return "user"; }
      get model() { return this.user.username; }
      get title() { return this.user.name || this.user.username; }
      get text() { return this.user.name || this.user.username; }
      get prefixType() { return "image"; }
      get prefixValue() {
        return this.user.avatar_template
          ? this.user.avatar_template.replace("{size}", "30")
          : null;
      }
      get suffixType() { return "text"; }
      get suffixValue() {
        // Show trust-level marker as a small italic suffix
        const tier = ["Newcomer","Basic","Member","Regular","Leader"][this.user.trust_level] || "";
        return tier;
      }
      get suffixCSSClass() { return "tavern-patron-tier"; }
    }

    return class extends BaseCustomSidebarSection {
      @tracked patrons = [];

      constructor() {
        super(...arguments);
        loadPatrons().then((users) => {
          this.patrons = users;
        });
      }
      get name() { return "honored-patrons"; }
      get title() { return I18n.t(themePrefix("liberty_tavern.sidebar.honored_patrons")); }
      get text() { return this.title; }
      get displaySection() { return true; }
      get hideSectionHeader() { return false; }
      get links() {
        return this.patrons.slice(0, limit).map((u) => new PatronLink({ user: u }));
      }
      get actions() { return []; }
      get actionsIcon() { return null; }
    };
  });
});
