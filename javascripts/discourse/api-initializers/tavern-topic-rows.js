// Per-view topic-row decorations for the discovery list views, matching the mockups:
//   Trending (hot)      → rank number (1, 2, 3 …)
//   Latest at the Bar   → a category-colored circle with the poster's initial
//   Top Shelf (top)     → a 5-star rating from the row's rank (Top Shelf is already sorted
//                         best-first, so 5 stars at the top step down the list)
// Plus a "· username" (OP) after the category on every row. The multi-avatar posters
// column is hidden and the category is restyled in common.scss §11.
//
// This runs as DOM decoration (rather than plugin-outlet connectors) because the Glimmer
// topic list exposes no stable per-row outlet on this Discourse version.
import { apiInitializer } from "discourse/lib/api";

// Discourse has no native topic rating. Top Shelf is already sorted best-first by Discourse's
// monthly top-score, so derive the stars from the row's RANK — 5 stars at the top, stepping down
// — giving a clean descending "highest-rated" column instead of stars that jump around the list.
function starsForRank(index) {
  if (index <= 1) return 5;
  if (index <= 4) return 4;
  if (index <= 8) return 3;
  if (index <= 14) return 2;
  return 1;
}

function starsMarkup(s) {
  return "★".repeat(s) + `<span class="tavern-row-badge__empty">${"★".repeat(5 - s)}</span>`;
}

function currentView(router) {
  const m = (router.currentRouteName || "").match(/^discovery\.(latest|top|hot)$/);
  return m ? m[1] : null;
}

function decorateRow(row, index, view) {
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
      badge.innerHTML = starsMarkup(starsForRank(index));
    }
    main.prepend(badge);
  } else if (view === "hot") {
    badge.textContent = index + 1; // keep the rank in sync as rows load
  } else if (view === "top") {
    badge.innerHTML = starsMarkup(starsForRank(index)); // keep stars in rank order as rows load
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
  let observer;
  let scheduled = false;

  function run() {
    const view = currentView(router);
    if (!view) {
      return;
    }
    document
      .querySelectorAll(".topic-list-item")
      .forEach((row, i) => decorateRow(row, i, view));
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
