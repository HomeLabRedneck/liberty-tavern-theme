// Per-view topic-row decorations for the discovery list views, matching the mockups:
//   Trending (hot)      → rank number (1, 2, 3 …)
//   Latest at the Bar   → a category-colored circle with the poster's initial
//   Top Shelf (top)     → a 5-star rating derived from the topic's like count
// Plus a "· username" (OP) after the category on every row. The multi-avatar posters
// column is hidden and the category is restyled in common.scss §11.
//
// This runs as DOM decoration (rather than plugin-outlet connectors) because the Glimmer
// topic list exposes no stable per-row outlet on this Discourse version. Rows carry
// data-topic-id, and the topic list model (service:discovery.currentTopicList) supplies
// like_count for the stars.
import { apiInitializer } from "discourse/lib/api";

// Discourse has no native topic rating — derive 1–5 stars from the reply count, with
// views as a capped tiebreaker that only tips topics sitting near a bucket boundary.
function starsFor(topic) {
  const replies = topic?.reply_count ?? topic?.posts_count ?? 0;
  const views = topic?.views ?? 0;
  const score = replies + Math.min(views / 2000, 4);
  if (score >= 150) return 5;
  if (score >= 60) return 4;
  if (score >= 25) return 3;
  if (score >= 8) return 2;
  return 1;
}

function currentView(router) {
  const m = (router.currentRouteName || "").match(/^discovery\.(latest|top|hot)$/);
  return m ? m[1] : null;
}

function decorateRow(row, index, view, byId) {
  const main = row.querySelector(".main-link");
  if (!main) {
    return;
  }
  const opLink = row.querySelector(".posters a[data-user-card]");
  const name = opLink?.getAttribute("data-user-card") || "";

  // Left decoration — rebuild if the view changed (className encodes the view).
  const wantClass = `tavern-row-badge tavern-row-badge--${view}`;
  let badge = main.querySelector(":scope > .tavern-row-badge");
  if (badge && badge.className !== wantClass) {
    badge.remove();
    badge = null;
  }
  if (!badge) {
    badge = document.createElement("span");
    badge.className = wantClass;
    if (view === "hot") {
      badge.textContent = index + 1;
    } else if (view === "latest") {
      badge.textContent = (name[0] || "•").toUpperCase();
      const wrap = row.querySelector(".badge-category__wrapper");
      const color = wrap?.style.getPropertyValue("--category-badge-color")?.trim();
      if (color) {
        badge.style.setProperty("--tavern-row-color", color);
      }
    } else if (view === "top") {
      const topic = byId.get(parseInt(row.dataset.topicId, 10));
      const s = starsFor(topic);
      badge.innerHTML =
        "★".repeat(s) +
        `<span class="tavern-row-badge__empty">${"★".repeat(5 - s)}</span>`;
    }
    main.prepend(badge);
  } else if (view === "hot") {
    badge.textContent = index + 1; // keep the rank in sync as rows load
  }

  // "· username" after the category.
  const bottom = row.querySelector(".link-bottom-line");
  if (bottom && name && !bottom.querySelector(".tavern-row-op")) {
    const span = document.createElement("span");
    span.className = "tavern-row-op";
    span.textContent = `· ${name}`;
    bottom.appendChild(span);
  }
}

export default apiInitializer("1.0", (api) => {
  const router = api.container.lookup("service:router");
  const discovery = api.container.lookup("service:discovery");
  let observer;
  let scheduled = false;

  function run() {
    const view = currentView(router);
    if (!view) {
      return;
    }
    const byId = new Map(
      (discovery?.currentTopicList?.topics || []).map((t) => [t.id, t])
    );
    document
      .querySelectorAll(".topic-list-item")
      .forEach((row, i) => decorateRow(row, i, view, byId));
  }

  function scheduleRun() {
    if (scheduled) {
      return;
    }
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      run();
    });
  }

  api.onPageChange(() => {
    observer?.disconnect();
    observer = null;
    if (!currentView(router)) {
      return;
    }
    requestAnimationFrame(() => {
      run();
      // Re-decorate rows added by infinite scroll or a period change.
      const target =
        document.querySelector(".topic-list tbody") ||
        document.querySelector(".topic-list");
      if (target) {
        observer = new MutationObserver(scheduleRun);
        observer.observe(target, { childList: true });
      }
    });
  });
});
