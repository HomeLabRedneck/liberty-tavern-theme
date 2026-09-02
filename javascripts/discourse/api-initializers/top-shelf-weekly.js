// Lock Top Shelf (/top) to the WEEKLY period for everyone.
//
// The site setting `top_page_default_timeframe = weekly` only pins ANONYMOUS visitors;
// logged-in users get an auto-adjusted period based on their last visit (so an admin lands
// on "quarter", etc.). The theme also hides the period chooser (common.scss §2), so there's
// no way to switch back — force every /top visit to ?period=weekly via a route redirect.
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (api) => {
  const router = api.container.lookup("service:router");

  router.on("routeDidChange", () => {
    if (router.currentRouteName !== "discovery.top") {
      return;
    }
    const period = router.currentRoute?.queryParams?.period;
    if (period !== "weekly") {
      // replaceWith (not transitionTo) so the auto-adjusted URL doesn't linger in history.
      // The resulting routeDidChange sees period === "weekly" and stops — no redirect loop.
      router.replaceWith("discovery.top", { queryParams: { period: "weekly" } });
    }
  });
});
