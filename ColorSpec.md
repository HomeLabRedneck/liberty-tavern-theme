# B2 — The Liberty Tavern · Color Spec

Element-by-element color reference for **Variant B2** (`Liberty Tavern Forum.html` → `discourse-homepage.jsx`).
For Claude Code handoff. All `oklch()` values are listed alongside resolved sRGB hex.

> **Source of truth:** these values live in `discourse-homepage.jsx` (chrome + main) and `discourse-shared.jsx` (sidebar + search dropdown). The two themes — **Light (default)** and **Dark** — are toggled by the `dark` prop. The accent rotates by `accentHue` (default `25`, "rust"); category colors are computed from each category's own hue.

---

## 1 · Theme tokens

These map 1:1 to Discourse's `--primary / --secondary / --tertiary` color-scheme variables.

| Token | Light | Dark | Notes |
|---|---|---|---|
| `--primary` (ink, body text) | `#1C1410` | `#EDE4CF` | |
| `--secondary` (page bg / parchment) | `#F5ECD6` | `#1A120C` | |
| `--secondary-low` (panel / sidebar bg) | `#EDE2C5` | `#251A12` | |
| `--primary-low` (hairlines, dividers) | `#D4C5A8` | `#3A2C20` | |
| `--primary-medium` (muted text, meta) | `#6B5A47` | `#A89880` | |
| `--tertiary` (accent — links, focus) | `oklch(50% 0.14 25)` → **#A43B38** | same | rotates with `accentHue` |
| `--tertiary-low` (accent fill bg) | `oklch(92% 0.05 25)` → **#FFD8D4** | `oklch(22% 0.05 25)` → **#2E100E** | |
| `--quaternary` (navy support) | `oklch(38% 0.10 250)` → **#0A4475** | same | rare badge tier |
| `--highlight` (brass / gold) | `oklch(72% 0.13 75)` → **#D49838** | same | header rule, CTAs, ribbons |
| `--danger` | `oklch(55% 0.18 25)` → **#C53637** | same | |
| `--success` | `oklch(48% 0.12 145)` → **#286F2F** | same | |

### Header chrome (always dark, both themes)
| Element | Light | Dark |
|---|---|---|
| `.d-header` background | `#1C1410` | `#0E0A06` |
| `.d-header` text | `#F5ECD6` | `#F5ECD6` |
| `.d-header` bottom rule | `2px solid #D49838` (highlight) | same |
| `.d-header` shadow | `0 2px 0 rgba(0,0,0,0.4)` | same |

---

## 2 · Category palette (hues)

Each category in `data.js` carries a `hue` (OKLCH H). The runtime helper:
`cat(h) = oklch(${dark ? 60 : 45}% 0.13 ${h})`.

| Category | Hue | Light (45% L) | Dark (60% L) |
|---|---|---|---|
| The Town Square | 25 (red) | **#90302E** | **#C25D58** |
| The Press Room | 250 (blue) | **#00579A** | **#3A84CA** |
| The Parlor | 145 (green) | **#146720** | **#47944C** |
| The Trading Post | 60 (amber) | **#873E00** | **#B76B1C** |
| The Hearth | 25 (red) | **#90302E** | **#C25D58** |
| The Cellar | 250 (blue) | **#00579A** | **#3A84CA** |

These flow through to: category-box left border, wax-seal logo background, featured-topic chevron, topic-list category badge, sidebar DM avatars, and search-dropdown chips.

---

## 3 · Element-by-element

### 3.1 Header — `.d-header`
| Element | Color |
|---|---|
| Bar background | `#1C1410` light / `#0E0A06` dark |
| Bar text + logo wordmark | `#F5ECD6` |
| Tagline ("Free Speech · Est. MDCCXCI") | `#D49838` (highlight) |
| Bottom rule | `2px solid #D49838` |
| Inactive nav pill text | `#F5ECD6` |
| **Active** nav pill background | `#D49838` (highlight) |
| **Active** nav pill text | `#1C1410` |
| Search button border (idle) | `#D49838 @ 53%` (`#D4983888`) |
| Search button text (idle) | `#D49838` |
| Search button bg (open) | `#D49838` |
| Search button text (open) | `#1C1410` |
| Sign In CTA bg | `#D49838` |
| Sign In CTA text | `#1C1410` |

### 3.2 Banner — `.custom-homepage-banner`
| Element | Color |
|---|---|
| Background gradient (light) | `linear-gradient(180deg, #1C1410 0%, #2A1810 100%)` |
| Background gradient (dark) | `linear-gradient(180deg, #0E0A06 0%, #1A120C 100%)` |
| Body text | `#F5ECD6` |
| Bottom rule | `3px solid #D49838` |
| Parchment dot overlay | `#D49838 @ 15% opacity` |
| Eyebrow ("❦ Welcome, friend ❦") | `#D49838` |
| H1 "Pull up a chair." | `#F5ECD6` |
| Body paragraph | `#F5ECD6 @ 85% opacity` |
| Primary CTA bg / text | `#D49838` / `#1C1410` |
| Secondary CTA bg / text / border | transparent / `#F5ECD6` / `#D49838 @ 53%` |
| Stats card bg | `rgba(0,0,0,0.4)` |
| Stats card border | `1px solid #D49838 @ 40%` (`#D4983866`) |
| Stats card corner ticks | `2px solid #D49838` |
| Stats card title eyebrow | `#D49838` |
| Stats card label dotted divider | `1px dotted rgba(245,236,214,0.15)` |
| Stats numerals | `#D49838` |
| Stats labels | `#F5ECD6 @ 70% opacity` |

### 3.3 Trending strip
| Element | Light | Dark |
|---|---|---|
| Background | `#EDE2C5` | `#251A12` |
| Border | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| Top accent | `3px solid #A43B38` (tertiary) | same |
| Eyebrow ("🔥 Trending Tonight") | `#A43B38` | same |
| Hairline between cells | `1px dotted #D4C5A8` | `1px dotted #3A2C20` |
| Per-card category eyebrow | category light hex | category dark hex |
| Title | `#1C1410` | `#EDE4CF` |
| Meta line | `#6B5A47` | `#A89880` |
| "All hot threads →" | `#6B5A47` | `#A89880` |

### 3.4 "The Rooms" — `.category-boxes`
| Element | Light | Dark |
|---|---|---|
| Section header H2 | `#1C1410` | `#EDE4CF` |
| Section header bottom rule | `2px solid #1C1410` | `2px solid #EDE4CF` |
| Section subtitle | `#6B5A47` | `#A89880` |
| `.category-box` bg | `#EDE2C5` | `#251A12` |
| `.category-box` border | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| `.category-box` left rule (4px) | category light hex | category dark hex |
| Hover shadow | `0 4px 12px rgba(0,0,0,0.15), inset 0 0 0 1px <category>` | same |
| Wax-seal logo bg | category hex | category hex |
| Wax-seal logo glyph | `#F5ECD6` | `#1A120C` |
| Wax-seal logo inner ring | `inset 0 0 0 2px #F5ECD6` light / `… 2px #1A120C` dark | |
| Category title | `#1C1410` | `#EDE4CF` |
| Category description | `#6B5A47` | `#A89880` |
| Featured-topic chevron | category hex | category hex |
| Featured-topic title text | `#6B5A47` | `#A89880` |
| Stat numerals | `#1C1410` | `#EDE4CF` |
| Stat labels | `#6B5A47` | `#A89880` |

### 3.5 Topic-list table (Trending / Latest / Top Shelf tabs)
| Element | Light | Dark |
|---|---|---|
| Header row text | `#6B5A47` | `#A89880` |
| Header row underline | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| Row underline | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| Topic title | `#1C1410` | `#EDE4CF` |
| Reply count numeral | `#1C1410` | `#EDE4CF` |
| Views / activity | `#6B5A47` | `#A89880` |
| "Hot" rank numeral | `#A43B38` (tertiary) | same |
| "Top" stars | `#D49838` (highlight) | same |
| "Latest" round avatar bg | category hex | category hex |
| "Latest" round avatar text | `#F5ECD6` | `#1A120C` |
| Category badge text | category hex | category hex |

### 3.6 Right context column (Badges + House Rules)
| Element | Light | Dark |
|---|---|---|
| Section H3 text | `#1C1410` | `#EDE4CF` |
| Section H3 bottom rule | `2px solid #1C1410` | `2px solid #EDE4CF` |
| Badge tile bg | `rgba(0,0,0,0.03)` | `rgba(0,0,0,0.2)` |
| Badge tile border | `1px solid <tier> @ 33%` (`<tier>55`) | same |
| Tier · common | `#6B5A47` | `#A89880` |
| Tier · rare | `#0A4475` (quaternary) | same |
| Tier · epic | `#A43B38` (tertiary) | same |
| Tier · legendary | `#D49838` (highlight) | same |
| Badge label | `#1C1410` | `#EDE4CF` |
| Badge "earned" meta | `#6B5A47` | `#A89880` |
| House Rules box border | `2px solid #A43B38` | same |
| House Rules eyebrow text | `#A43B38` | same |
| House Rules eyebrow bg (notch) | `#F5ECD6` (page bg) | `#1A120C` |
| Rules list text | `#6B5A47` | `#A89880` |

### 3.7 Left sidebar — `.sidebar-wrapper` (from `discourse-shared.jsx`)
| Element | Light | Dark |
|---|---|---|
| Sidebar bg | `#EDE2C5` | `#251A12` |
| Right border | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| Section header text | `#6B5A47` | `#A89880` |
| Link text | `#1C1410` | `#EDE4CF` |
| Link prefix icon | `#6B5A47` | `#A89880` |
| Active link bg | `rgba(28,20,16,0.06)` | `rgba(245,236,214,0.08)` |
| Active link left rule | `3px solid #A43B38` (accent) | same |
| Notification badge text | `#A43B38` | same |
| Channel · "general" icon | `#0089D0` | `#0079BF` |
| Channel · "staff" icon | `#B94642` | same |
| DM avatar bg | category hex (per hue) | category hex |
| Patron name | `#1C1410` | `#EDE4CF` |
| Patron rep meta | `#6B5A47` | `#A89880` |
| Patron avatar bg | `oklch(45/60% 0.13 ${accentHue})` (rust by default) | |

### 3.8 Search dropdown — `.search-menu` (from `discourse-shared.jsx`)
| Element | Light | Dark |
|---|---|---|
| Panel bg | `#F5ECD6` | `#1A120C` |
| Panel text | `#1C1410` | `#EDE4CF` |
| Panel border | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| Panel shadow | `0 12px 32px rgba(28,20,16,0.18)` | `0 12px 32px rgba(0,0,0,0.6)` |
| Section divider | `1px solid #D4C5A8` | `1px solid #3A2C20` |
| Section eyebrow | `#6B5A47` | `#A89880` |
| Result icon | `#6B5A47` | `#A89880` |
| Highlight `<mark>` bg | `#FFCF77` | `#4C2200` |
| Category chip text + border | category hex (text) / category hex @ 33% (border) | same |
| Filter shortcut `<code>` text | `#A43B38` (tertiary) | same |
| Filter shortcut `<code>` bg | `#EDE2C5` | `#251A12` |
| Footer text | `#6B5A47` | `#A89880` |
| "Advanced search →" link | `#A43B38` | same |

### 3.9 Footer code-strip
| Element | Light | Dark |
|---|---|---|
| Background | `#1C1410` | `#0E0A06` |
| Body text | `rgba(245,236,214,0.5)` | same |
| Top rule | `1px solid #D49838 @ 33%` (`#D4983855`) | same |
| Inline `<code>` text | `#D49838` | same |

---

## 4 · Quick CSS-variable bootstrap

Drop this into a Discourse `common.scss` to seed the same palette:

```scss
:root {
  --secondary:        #F5ECD6;
  --secondary-low:    #EDE2C5;
  --primary:          #1C1410;
  --primary-medium:   #6B5A47;
  --primary-low:      #D4C5A8;
  --tertiary:         #A43B38;   /* accent / links */
  --tertiary-low:     #FFD8D4;
  --quaternary:       #0A4475;
  --highlight:        #D49838;   /* brass — CTAs, header rule */
  --danger:           #C53637;
  --success:          #286F2F;

  --header-bg:        #1C1410;
  --header-text:      #F5ECD6;
}

[data-theme="dark"] {
  --secondary:        #1A120C;
  --secondary-low:    #251A12;
  --primary:          #EDE4CF;
  --primary-medium:   #A89880;
  --primary-low:      #3A2C20;
  --tertiary-low:     #2E100E;
  --header-bg:        #0E0A06;
}
```

## 5 · Color scheme JSON (Discourse import)

For `discourse-theme/color_schemes/liberty-tavern.json`:

```json
{
  "name": "Liberty Tavern",
  "colors": {
    "primary":         "1C1410",
    "secondary":       "F5ECD6",
    "tertiary":        "A43B38",
    "quaternary":      "0A4475",
    "header_background":"1C1410",
    "header_primary":  "F5ECD6",
    "highlight":       "D49838",
    "danger":          "C53637",
    "success":         "286F2F",
    "love":            "A43B38"
  }
}
```

```json
{
  "name": "Liberty Tavern Dark",
  "colors": {
    "primary":         "EDE4CF",
    "secondary":       "1A120C",
    "tertiary":        "A43B38",
    "quaternary":      "0A4475",
    "header_background":"0E0A06",
    "header_primary":  "F5ECD6",
    "highlight":       "D49838",
    "danger":          "C53637",
    "success":         "286F2F",
    "love":            "A43B38"
  }
}
```

---

## 6 · Notes for the implementer

1. **Tertiary doesn't change between light/dark** — only its `-low` companion does. Same for highlight, danger, success, quaternary.
2. **Category hexes are derived, not hand-picked.** If you add a category in `data.js`, give it a `hue` and the runtime helper produces both light + dark variants. Don't hardcode hex into category records.
3. **Header chrome is always dark** in both themes — only the *exact* shade shifts (`#1C1410 → #0E0A06`).
4. **Hover tint on category boxes** uses `rgba(0,0,0,0.15)` for the drop shadow + a 1-px inset of the category color. Don't change the row's bg on hover; only its shadow + 2px X-translate.
5. **Header pill active state** flips fg/bg — brass background, ink text. Inactive pills are transparent on dark wood with cream text.
6. **Brass (`#D49838`) is used sparingly:** header rule, active nav pill, primary CTA, banner stats numerals, top-shelf stars, legendary badges, ribbon eyebrows. Don't sprinkle it elsewhere.
