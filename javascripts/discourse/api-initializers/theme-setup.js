import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import TavernBanner from "../components/tavern-banner";
import TavernRightColumn from "../components/tavern-right-column";
import TavernListHeading from "../components/tavern-list-heading";

export default apiInitializer("1.13.0", (api) => {
  // Phase 1: render homepage banner
  if (settings.show_homepage_banner) {
    api.renderInOutlet("discovery-list-container-top", TavernBanner);
  }

  // Phase 4: render the right-column rail (Badges + House Rules) into the same
  // discovery content wrapper (#list-area) so common.scss §10 can grid it beside
  // the list. The component self-gates via shouldShow (settings + /^discovery\./).
  if (settings.show_right_column) {
    api.renderInOutlet("discovery-list-container-top", TavernRightColumn);
  }

  // Section heading for the topic-list views (Trending / Latest at the Bar / Top Shelf).
  // Self-gates to those three routes; renders nothing on Rooms (which has its own heading).
  api.renderInOutlet("discovery-list-container-top", TavernListHeading);

  // Phase 2: rename nav pill labels and Sign In button text
  // NOTE: theme locales/en.yml cannot override js.* core strings (theme locale namespace
  // is isolated). JS patch is the correct approach for an English-only forum.
  // top_menu site setting must be set to "hot|latest|categories|top" via Admin → Settings
  // for the Trending (/hot) pill to appear (top_menu is not a themeable setting).
  const locale = (typeof i18n.currentLocale === "function" ? i18n.currentLocale() : i18n.locale) || "en";
  const translations = i18n.translations?.[locale];
  if (translations?.js) {
    const { filters } = translations.js;
    if (filters) {
      // filters.latest.title is a pluralized key — must assign an object, not a string.
      // Guard each assignment so hot-reload double-patching is a no-op.
      if (filters.latest && filters.latest.title?.other !== "Latest at the Bar (%{count})") {
        filters.latest.title = {
          zero: "Latest at the Bar",
          one: "Latest at the Bar (%{count})",
          other: "Latest at the Bar (%{count})"
        };
      }
      if (filters.top && filters.top.title !== "Top Shelf") {
        filters.top.title = "Top Shelf";
      }
      if (filters.hot && filters.hot.title !== "Trending") {
        filters.hot.title = "Trending";
      }
      if (filters.categories && filters.categories.title !== "Rooms") {
        filters.categories.title = "Rooms";
      }
    }
    // Rename "Log In" button label to "Sign In"
    if (translations.js.log_in !== undefined && translations.js.log_in !== "Sign In") {
      translations.js.log_in = "Sign In";
    }
  }
});
