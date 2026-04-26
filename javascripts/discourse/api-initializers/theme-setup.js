import { apiInitializer } from "discourse/lib/api";
import TavernBanner from "../components/tavern-banner";

export default apiInitializer("1.13.0", (api) => {
  if (!settings.show_homepage_banner) return;
  api.renderInOutlet("discovery-list-container-top", TavernBanner);
});
