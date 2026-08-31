// Mobile room-card badges. On phones Discourse renders each category as a mini topic-list
// table with no badge slot, so the desktop room-card initial badge is missing. Inject one:
// read the category's colour (the card carries it as an inline border-color) and the first
// letter of its name, then prepend a coloured square. Also expose the colour as --tavern-cat
// so common.scss §12 can tint the card's latest-thread quote bar. Hidden on desktop via CSS.
import { apiInitializer } from "discourse/lib/api";

function decorate() {
  document.querySelectorAll(".category-list-item.category").forEach((box) => {
    if (box.querySelector(":scope > .tavern-cat-badge")) {
      return;
    }
    const name = box.querySelector(".category-name")?.textContent.trim() || "?";
    const color =
      box.style.borderColor || getComputedStyle(box).borderLeftColor || "#7a1f1f";
    box.style.setProperty("--tavern-cat", color);

    const badge = document.createElement("span");
    badge.className = "tavern-cat-badge";
    badge.textContent = name[0].toUpperCase();
    box.prepend(badge);
  });
}

export default apiInitializer("1.0", (api) => {
  let observer;
  api.onPageChange(() => {
    observer?.disconnect();
    observer = null;
    requestAnimationFrame(() => {
      decorate();
      // Re-decorate cards that Ember re-renders (route re-entry, live category updates).
      const target = document.querySelector(".category-list");
      if (target) {
        observer = new MutationObserver(() => requestAnimationFrame(decorate));
        observer.observe(target, { childList: true, subtree: true });
      }
    });
  });
});
