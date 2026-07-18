# RANCH RUSH — Art Direction + UI Spec

**Version 1.0 — implementation-ready**
Target: ONE self-contained HTML file. Vanilla JS + CSS. No external assets — emoji sprites, CSS shapes/gradients, inline SVG, WebAudio-synthesized SFX.
Personas: UI Designer (lead) + Whimsy Injector + Visual Storyteller + Technical Artist.

---

## 0. Art Direction in One Paragraph

**"Golden-hour storybook farm."** Warm cream paper, sun-baked wood, honey gold, and meadow green — a hand-painted roadside farmstand, not a corporate dashboard. Every level tells a one-day story: the sky slides from morning blue to peach dusk as the timer runs, so players *feel* the day ending without reading a clock. Chunky rounded type, thick wooden bevels, soft drop shadows, emoji as sprites treated like stickers on a scrapbook. Juice everywhere it rewards, calm everywhere it informs. Performance rule (Technical Artist): animate **transform + opacity only**, one `requestAnimationFrame` loop, ≤ 12 pooled particle nodes alive at once, `contain: layout paint` on every plot.

---

## 1. Visual Identity

### 1.1 Color Tokens (CSS Custom Properties)

Copy-paste block. Light surfaces are "paper & wood"; the HUD uses the dark-panel variant so gold/white numerals pop against the bright field.

```css
:root {
  /* ---- World ---- */
  --c-sky-day:    #A8DDF0;  /* morning sky (gradient top: #C4EAF8) */
  --c-sky-dusk:   #F4A26B;  /* end-of-level sky (gradient top: #FDD9A0) */
  --c-grass:      #7BB661;  /* meadow / field background */
  --c-soil:       #8A5A33;  /* tilled plot */
  --c-soil-wet:   #6B4423;  /* watered plot (darker = watered, redundant w/ 💧 icon) */
  --c-water:      #4FA9E0;  /* water tool, focus rings, info */

  /* ---- UI Surfaces ---- */
  --c-wood:       #B07A45;  /* wooden buttons, frames */
  --c-wood-dark:  #7A4E2A;  /* wood bevel/border, pressed state */
  --c-paper:      #FFF6E3;  /* order tickets, cards */
  --c-panel:      #F6E7C8;  /* light panels (menus, settings) */
  --c-panel-dark: #33261A;  /* DARK HUD VARIANT — top bar, toolbar (use at 92% alpha: rgba(51,38,26,.92)) */

  /* ---- Semantics ---- */
  --c-gold:       #FFC93C;  /* coins, stars, primary accent */
  --c-success:    #4E9F3D;  /* fills: order complete, ready */
  --c-success-ink:#2E6B22;  /* success TEXT on paper (≥4.5:1) */
  --c-danger:     #E0533D;  /* fills: failing patience bar */
  --c-danger-ink: #B93B2A;  /* danger TEXT on paper (≥4.5:1) */

  /* ---- Ink ---- */
  --c-text:       #3B2A1A;  /* cocoa — primary text on paper/panel (~11:1) */
  --c-text-soft:  #6E5A44;  /* secondary text on paper (~5:1) */
  --c-text-inv:   #FFF8EC;  /* text on dark panel / wood (~11:1 on panel-dark) */
}
```

**Dark-panel HUD variant** — apply as a class, everything inside inherits:

```css
.panel-dark {
  background: rgba(51, 38, 26, .92);          /* --c-panel-dark @ 92% */
  color: var(--c-text-inv);
  border-bottom: 3px solid var(--c-wood-dark);
  box-shadow: 0 3px 0 rgba(0,0,0,.18);
}
.panel-dark .stat-gold { color: var(--c-gold); }      /* ≈8:1 on panel-dark — numerals OK */
.panel-dark .stat-danger { color: #FF8A73; }          /* lightened danger for dark bg */
```

### 1.2 Typography — No Webfonts, Still Distinctive

One family, the **rounded system stack** — reads "cozy game" on every OS with zero bytes downloaded:

```css
:root {
  --font-round: ui-rounded, "SF Pro Rounded", "Hiragino Maru Gothic ProN",
                "Arial Rounded MT Bold", "Trebuchet MS", system-ui, sans-serif;
}
body { font-family: var(--font-round); color: var(--c-text); }
```

**Display treatment** (title, "LEVEL COMPLETE!"): make the rounded stack *chunky* with a sticker outline + drop — this is the distinctive move, not a font:

```css
.display {
  font-weight: 800;
  letter-spacing: .02em;
  color: var(--c-paper);
  -webkit-text-stroke: 5px var(--c-wood-dark);
  paint-order: stroke fill;               /* stroke behind fill = clean sticker */
  text-shadow: 0 4px 0 rgba(0,0,0,.22);
}
```

HUD numerals: `font-variant-numeric: tabular-nums;` so cash/timer don't jitter.

**Type scale** (fluid, desktop → 380px):

```css
:root {
  --fs-xs:   0.75rem;                        /* 12px — ticket metadata */
  --fs-sm:   0.875rem;                       /* 14px — labels, secondary */
  --fs-base: 1rem;                           /* 16px — body, ticket items */
  --fs-lg:   1.25rem;                        /* 20px — HUD stats, buttons */
  --fs-xl:   clamp(1.375rem, 3.5vw, 1.75rem);/* 22–28px — panel headings */
  --fs-hero: clamp(2rem, 8vw, 3.5rem);       /* 32–56px — title, results banner */
  line-height: 1.35;
}
```

Weights: 400 body, 600 labels/buttons, 800 display. Nothing else.

---

## 2. Layout Blueprint

Desktop-first, responsive to 380px portrait. One grid container, `100dvh`, no page scroll.

### 2.1 Desktop (≥ 760px)

```
┌──────────────────────────────────────────────────────┐
│  HUD  💰 240   ⏱ 2:14   [goal ▓▓▓▓░░ 4/7]   ⏸  🔊    │ 56px, .panel-dark
├────────────┬─────────────────────────────────────────┤
│  ORDERS    │                                         │
│ ┌────────┐ │           FARM FIELD GRID               │
│ │ticket 1│ │        (sky gradient behind,            │
│ ├────────┤ │       fence SVG top border,             │
│ │ticket 2│ │      plots centered, aspect 1:1)        │
│ ├────────┤ │                                         │
│ │ticket 3│ │                                         │
│ └────────┘ │                                         │
├────────────┴─────────────────────────────────────────┤
│ TOOLBAR  [🌾][🥕][🍅][🌽] │ [💧 water][🧺 harvest]    │ 76px, .panel-dark
└──────────────────────────────────────────────────────┘
```

```css
.game {
  display: grid;
  height: 100dvh;
  grid-template-areas:
    "hud     hud"
    "orders  field"
    "toolbar toolbar";
  grid-template-columns: minmax(220px, 260px) 1fr;
  grid-template-rows: 56px 1fr 76px;
}
.hud     { grid-area: hud; }
.orders  { grid-area: orders; overflow-y: auto; padding: 12px;
           display: flex; flex-direction: column; gap: 10px; }
.field   { grid-area: field; display: grid; place-items: center;
           position: relative; overflow: hidden; }   /* sky layers live here */
.toolbar { grid-area: toolbar; display: flex; align-items: center;
           justify-content: center; gap: 8px; padding: 8px 12px; }

/* The plot grid itself — --cols/--rows set per level from JS */
.plots {
  display: grid;
  grid-template-columns: repeat(var(--cols, 6), var(--plot, 84px));
  grid-template-rows:    repeat(var(--rows, 4), var(--plot, 84px));
  gap: 8px;
}
.plot { contain: layout paint; position: relative; border-radius: 12px;
        background: var(--c-soil); border: 3px solid var(--c-wood-dark); }
```

JS sizes `--plot` on resize: `min( (fieldW-gaps)/cols, (fieldH-gaps)/rows, 96 )`, floor **48px** (hit target, §7).

### 2.2 Phone Portrait (≤ 600px, works at 380px)

Order rail becomes a horizontal ticket strip under the HUD; toolbar stays thumb-reachable at bottom.

```css
@media (max-width: 600px) {
  .game {
    grid-template-areas: "hud" "orders" "field" "toolbar";
    grid-template-columns: 1fr;
    grid-template-rows: 48px 96px 1fr 68px;
  }
  .orders { flex-direction: row; overflow-x: auto; overflow-y: hidden;
            scroll-snap-type: x mandatory; padding: 8px; }
  .ticket { flex: 0 0 132px; scroll-snap-align: start; }
  .hud { font-size: var(--fs-sm); }         /* stats compress; goal bar keeps ≥88px width */
}
```

HUD internals (both sizes): `display:flex; gap:12px;` — cash chip (💰 + tabular number) · timer chip (⏱ + m:ss) · goal progress bar (flex:1, min-width:88px, wooden frame, gold fill, "4/7" label inside) · pause button · sound button, both 44×44 min.

---

## 3. Sprite System (Emoji + Inline SVG)

### 3.1 Emoji Casting Sheet

Emoji are rendered as **text nodes inside the plot** (never canvas — free crispness at every DPI). Size via `font-size: calc(var(--plot) * .62)`, centered with `display:grid; place-items:center`.

**Crops — 4 growth stages.** Stage 0–1 shared across crops (readable at a glance), stage 2 universal leafy juvenile, stage 3 unique ripe emoji:

| Crop       | S0 seeded        | S1 sprout | S2 growing | S3 READY | Sell icon |
|------------|------------------|-----------|------------|----------|-----------|
| Wheat      | 🌱 (@ 45% scale) | 🌱        | 🌿         | 🌾       | 🌾        |
| Carrot     | 🌱 (@ 45%)       | 🌱        | 🌿         | 🥕       | 🥕        |
| Tomato     | 🌱 (@ 45%)       | 🌱        | 🌼 (flower)| 🍅       | 🍅        |
| Corn       | 🌱 (@ 45%)       | 🌱        | 🌿         | 🌽       | 🌽        |
| Strawberry | 🌱 (@ 45%)       | 🌱        | 🌼         | 🍓       | 🍓        |
| Pumpkin    | 🌱 (@ 45%)       | 🌱        | 🌿         | 🎃       | 🎃        |

**Animals** (live on grass tiles, produce on a cycle): 🐔 → 🥚 · 🐄 → 🥛 · 🐑 → 🧶.
**Machines** (processors, later levels): ⚙️ Mill (🌾→🥖) · 🫕 Jam Pot (🍓→🍯) · 🧈 Churn (🥛→🧈).
**Field dressing:** 🪨 rock obstacle, 🌻 decorative border clumps, 🦅→ use 🐦‍⬛ crow event (steals a ready crop, click to shoo).

**UI icons:** 💰 cash · ⏱ timer · ⭐/☆ stars · 💧 water tool · 🧺 harvest tool · ⏸ pause · ⚙️ settings · 🔊/🔇 sound · 🔒 locked level · 👨‍🌾/👩‍🌾/🧑‍🌾 profile slots · ⚠️ warning · ❤️ patience.

### 3.2 Growth-Stage Rendering Recipe

Scale + swap. One span per plot, JS swaps `textContent` and a `data-stage` attribute; CSS handles the look:

```css
.plot .crop { transition: transform .35s cubic-bezier(.34,1.56,.64,1); /* grow-in overshoot */
              transform-origin: 50% 85%; }               /* grows "out of the soil" */
.plot[data-stage="0"] .crop { transform: scale(.45); opacity: .85; }
.plot[data-stage="1"] .crop { transform: scale(.65); }
.plot[data-stage="2"] .crop { transform: scale(.85); }
.plot[data-stage="3"] .crop { transform: scale(1); }     /* + ready-pulse, §5.3 */
.plot.watered { background: var(--c-soil-wet); }         /* + 💧 badge, §7 */
```

Each stage swap fires the transition (scale animates, emoji swaps instantly at swap-time — reads as a growth "pop"). Ready state additionally gets the pulse glow and a ✨ corner badge (non-color cue).

**Technical Artist notes:**
- Emoji glyphs differ per OS (Windows flat / Apple glossy). Palette must not depend on emoji hues — it doesn't; emoji sit on soil brown, always contrasted.
- Feature-detect risky glyphs (🐦‍⬛, 🫕) at boot: draw to an offscreen canvas, if rendered width matches tofu/replacement fallback to (🐦‍⬛→🐧? no — →🦉; 🫕→🍲). Keep a `FALLBACKS = {'🐦‍⬛':'🦉','🫕':'🍲'}` map.
- Never animate `font-size` — scale transforms only (compositor-friendly).

### 3.3 Hand-Drawn Inline SVG (the 3 worth doing)

Emoji can't do structure. These three carry the "hand-built farmstand" feel; each < 1KB.

**A) Hanging wooden sign** (title screen logo board; text overlaid in HTML so the font stack applies):

```html
<svg class="sign" viewBox="0 0 320 180" aria-hidden="true">
  <path d="M84 0 L100 46 M236 0 L220 46" stroke="#8A6A3F" stroke-width="7" stroke-linecap="round"/>
  <rect x="18" y="46" width="284" height="116" rx="14" fill="#B07A45" stroke="#7A4E2A" stroke-width="7"/>
  <path d="M18 84 H302 M18 122 H302" stroke="#8A5A2E" stroke-width="3" opacity=".55"/>
  <path d="M56 102 q12 -9 24 0 t24 0" stroke="#936237" stroke-width="3" fill="none" opacity=".7"/>
  <circle cx="40" cy="64" r="4.5" fill="#5B3A1E"/> <circle cx="280" cy="64" r="4.5" fill="#5B3A1E"/>
  <circle cx="40" cy="144" r="4.5" fill="#5B3A1E"/> <circle cx="280" cy="144" r="4.5" fill="#5B3A1E"/>
</svg>
```

**B) Order ticket** (paper card, zig-zag torn bottom, nail pin — the game's signature UI object). Used as the ticket background via absolutely-positioned SVG or `background-image: url("data:image/svg+xml,...")` (URL-encode `#` as `%23`):

```html
<svg class="ticket-bg" viewBox="0 0 200 132" preserveAspectRatio="none" aria-hidden="true">
  <path d="M6 10 Q6 4 12 4 H188 Q194 4 194 10 V116
           L184 124 L174 116 L164 124 L154 116 L144 124 L134 116 L124 124 L114 116
           L104 124 L94 116 L84 124 L74 116 L64 124 L54 116 L44 124 L34 116
           L24 124 L14 116 L6 116 Z"
        fill="#FFF6E3" stroke="#D9C6A0" stroke-width="2"/>
  <line x1="14" y1="30" x2="186" y2="30" stroke="#D9C6A0" stroke-width="2" stroke-dasharray="4 5"/>
  <circle cx="100" cy="13" r="5" fill="#7A4E2A"/><circle cx="100" cy="12" r="2" fill="#C9A26B"/>
</svg>
```

Ticket content (customer emoji, wanted items, patience bar) is HTML layered above with `position:relative`.

**C) Fence tile** (repeat-x strip separating sky from field, also frames the level map). As data-URI background:

```html
<svg viewBox="0 0 64 48" aria-hidden="true">
  <path d="M8 10 L14 3 L20 10 V48 H8 Z"  fill="#B07A45" stroke="#7A4E2A" stroke-width="2.5"/>
  <path d="M44 10 L50 3 L56 10 V48 H44 Z" fill="#B07A45" stroke="#7A4E2A" stroke-width="2.5"/>
  <rect x="0" y="16" width="64" height="8" rx="3" fill="#A9713D" stroke="#7A4E2A" stroke-width="2"/>
  <rect x="0" y="32" width="64" height="8" rx="3" fill="#A9713D" stroke="#7A4E2A" stroke-width="2"/>
</svg>
```

```css
.fence { height: 48px; background: url("data:image/svg+xml,...") repeat-x bottom / 64px 48px; }
```

(Also reuse the wood-rect style from A for the goal progress-bar frame — same strokes, zero new drawing.)

---

## 4. Screen Inventory (Wireframes in Words)

Screens are sibling `<section>`s toggled with a `.active` class; cross-fade 250ms. Overlays (pause/results) stack above the frozen game.

### 4.1 Title Screen
Full-bleed day-sky gradient; 3 CSS clouds drifting (§8); grass band bottom 22% with fence SVG along its top edge; 🐔 wandering on the grass; 🏠 barn emoji (large, right side) — the easter-egg target. **Center-top:** the wooden sign SVG swings in from above (600ms, `cubic-bezier(.22,1.4,.36,1)`, slight rotate settle) with "RANCH RUSH" in `.display` overlaid, 🌾 flanking. **Center stack** (vertical, 12px gap, buttons 260×56 wood style): `▶ Continue` (only rendered when the active slot has progress — top position, gold rim), `🌱 New Game`, `♾ Free Play`, `⚙️ Settings`. **Bottom-left:** profile chip (§4.7). **Top-right:** 🔊 toggle. **Bottom-right:** `v1.0` in `--fs-xs`/`--c-text-soft`.

### 4.2 Level Select Map
Header bar (light `--c-panel`): `← back` (44px), centered "CHOOSE A DAY", right chip `⭐ 23/60`. Body: grass background, a full-width inline-SVG **dirt path** (`stroke:#8A5A33; stroke-width:26; stroke-dasharray:2 14; stroke-linecap:round; opacity:.8`) serpentining through **20 nodes** laid out 4-per-row, alternating direction (S-curve). Node = 56px circle, wood fill + `--c-wood-dark` border 4px: **completed** → gold rim + level number + mini star row beneath (`⭐⭐☆` at 14px, `☆` uses `--c-text-soft` so it reads by shape not color); **unlocked-next** → normal wood + soft bounce idle (reduced-motion: static gold dot badge); **locked** → desaturated (`filter:grayscale(.7) brightness(.85)`) + 🔒. Tap node → small paper card pops above it (scale-in 200ms): "Day 7 · Goal: 💰 350 · best ⭐⭐☆" + `Play ▶`. Scrolls vertically on phone.

### 4.3 In-Level HUD
As blueprint §2. Left→right: 💰 cash chip (gold numeral, tabular), ⏱ timer chip (turns `#FF8A73` + gains ⚠️ icon under 15s — color + icon), **goal progress bar** (wooden frame, gold fill, embedded label "💰 240/350"; on goal reached: fill flips to `--c-success` and a ⭐ stamps on its end-cap), ⏸ pause (44px), 🔊 (44px). Order tickets fill the rail (§2), each: customer emoji header (🧑‍🌾/👵/🧒…), wanted items row (`🥕×2 🍅×1` with dimmed→lit states as delivered), patience bar bottom (❤️ icon + bar: `--c-success` >50% → `--c-gold` 20–50% → `--c-danger` <20% + shake §5.5 + 😟 face swap — three redundant signals). Toolbar: seed buttons (crop emoji + price underneath, selected = gold ring + lifted 2px), divider, 💧 water, 🧺 harvest. Selected tool also swaps the field cursor badge.

### 4.4 Pause Menu
Overlay `rgba(20,14,8,.55)` + `backdrop-filter: blur(2px)` (guard behind `@supports`). Game root gets `.paused` → `animation-play-state: paused` on all field animations; rAF loop halts. Center wooden panel (320px, `--c-panel`, wood border, drop shadow), sign-style header "PAUSED", stacked buttons: `▶ Resume` (primary gold), `↻ Restart Day`, `⚙️ Settings`, `🗺 Quit to Map` (quit = plain, not danger — no loss). `Esc`/⏸ resumes.

### 4.5 Level Results (Star Reveal)
Same overlay. Paper panel drops in (450ms bounce). Header `.display`: "DAY COMPLETE!" (fail: "OUT OF TIME!" with 🥀 and warmer copy: "The rooster says try again!"). Below: **three 72px star slots** (grey `☆` placeholders); earned stars pop in staggered 0 / 350 / 700ms with burst §5.6 + rising SFX pitch per star. Stats rows count up over 800ms (`Orders filled 6/7`, `Coins earned 💰 382`, `Best combo ×3`). Star thresholds printed under slots ("⭐ 250 · ⭐⭐ 350 · ⭐⭐⭐ 450") so goals are legible. Footer buttons: `Replay`, `Map`, `Next ▶` (primary; fail variant: `Retry` primary).

### 4.6 Settings
Paper panel, rows 56px tall, label left / control right (toggles 52×32, wooden track, gold knob, knob also shows ✓/✕ glyph — not color-only): `🔊 Sound effects`, `🌬 Ambient sounds`, `🎞 Reduce motion` (three-state: Auto (OS) / On / Off — default Auto), `👤 Profile slot` (opens slot picker), and **`🗑 Reset save`** — danger-styled (`--c-danger-ink` text, outlined). Reset requires a second confirm dialog: "Erase ALL progress for slot 1? This can't be undone." `[Cancel] [Erase — hold 1s]` — hold-to-confirm fills a red progress ring; releasing early cancels. Footer: "Made with 🌾 + WebAudio".

### 4.7 Save-Slot / Profile Indicator
Persistent chip (title screen bottom-left; map header): rounded wooden pill `👨‍🌾 Slot 1 · ⭐23`. Tap → picker with 3 slot cards (emoji face 👨‍🌾/👩‍🌾/🧑‍🌾, total stars, levels done, "Empty — start here!" for fresh slots). Storage: `localStorage` keys `ranchrush.slot{1..3}` (JSON: levels, stars, settings) + `ranchrush.activeSlot`. Every screen shows which farm you're on — no accidental overwrite.

---

## 5. Juice & Animation Spec — 8 Moments

Global: `--ease-pop: cubic-bezier(.34,1.56,.64,1);` (back-out overshoot). All recipes transform/opacity only. Every recipe has a reduced-motion fallback (§7).

### 5.1 Harvest Pop
Crop scales up with a twist, then shrinks away rising; a `+💰5` floater rises. 280ms — snappy, this happens hundreds of times.

```css
@keyframes harvest-pop {
  0%   { transform: scale(1) rotate(0); opacity: 1; }
  35%  { transform: scale(1.35) rotate(-8deg); }
  100% { transform: scale(.1) translateY(-26px) rotate(6deg); opacity: 0; }
}
.crop.harvesting { animation: harvest-pop .28s cubic-bezier(.36,.07,.19,.97) forwards; }

@keyframes floater { to { transform: translateY(-34px); opacity: 0; } }
.floater { position: absolute; font-size: var(--fs-sm); font-weight: 600; color: var(--c-gold);
           text-shadow: 0 1px 0 var(--c-wood-dark); animation: floater .6s ease-out forwards; }
```

### 5.2 Coin Arc to HUD
Two-track arc — outer node animates X linearly, inner glyph animates Y with an overshoot ease → coin rises *above* the wallet then settles in. JS sets `--dx/--dy` from `plotRect → cashChipRect`, spawns from a 12-node pool, on `animationend` bumps the cash number + cash chip does a 120ms `scale(1.15)` blip.

```css
.fx-coin        { position: fixed; z-index: 90; pointer-events: none;
                  animation: coin-x .6s linear forwards; }
.fx-coin .g     { display: block; animation: coin-y .6s cubic-bezier(.17,.89,.32,1.28) forwards; }
@keyframes coin-x { to { transform: translateX(var(--dx)); } }
@keyframes coin-y { to { transform: translateY(var(--dy)) scale(.55); opacity: .9; } }
```

Stagger multiple coins 60ms apart, cap 5 per harvest (pool the rest into the last coin's value).

### 5.3 Plot Ready Pulse / Glow
Calm heartbeat, not an alarm — it must be ignorable while planning. Pairs with the ✨ badge (non-color cue).

```css
@keyframes ready-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(255,201,60,0); transform: scale(1); }
  50%      { box-shadow: 0 0 0 5px rgba(255,201,60,.45), 0 0 16px 4px rgba(255,201,60,.30);
             transform: scale(1.035); }
}
.plot[data-stage="3"] { animation: ready-pulse 1.6s ease-in-out infinite; }
```

### 5.4 Order Ticket Slide-In
New ticket swings in from the rail edge like paper slapped on a board, tiny rotation settle. (Phone: same keyframes, tickets enter from the right of the strip.)

```css
@keyframes ticket-in {
  0%   { transform: translateX(-115%) rotate(-5deg); opacity: 0; }
  70%  { transform: translateX(4%)   rotate(1.5deg); opacity: 1; }
  100% { transform: translateX(0)    rotate(0); }
}
.ticket.enter { animation: ticket-in .42s cubic-bezier(.22,1.2,.36,1) both; }
```

Exit on completion: `translateX(-10%) scale(.9) → opacity 0`, 250ms ease-in, with a ✅ stamp scale-in first (150ms).

### 5.5 Patience-Bar Shake (Low)
Shake bursts, not continuous — 25% of a 1.8s cycle wiggles, 75% rests (continuous shake is stressful and unreadable). Applies to the whole ticket when patience < 20%.

```css
@keyframes patience-shake {
  0%,25%,100% { transform: translateX(0) rotate(0); }
  4%  { transform: translateX(-3px) rotate(-1deg); }
  9%  { transform: translateX(3px)  rotate(1deg); }
  14% { transform: translateX(-2px); }
  19% { transform: translateX(2px); }
}
.ticket.low { animation: patience-shake 1.8s ease-in-out infinite;
              outline: 3px solid var(--c-danger); }
```

### 5.6 Star Burst (Level Complete)
Per star: pop with back-overshoot + a conic-ray flash behind it (`::before`) + 4 pooled ✨ particles flung outward. Stagger 0/350/700ms (§4.5).

```css
@keyframes star-pop {
  0%   { transform: scale(0) rotate(-40deg); opacity: 0; }
  70%  { transform: scale(1.3) rotate(6deg); opacity: 1; }
  100% { transform: scale(1) rotate(0); }
}
.star.earned { animation: star-pop .5s var(--ease-pop) both;
               filter: drop-shadow(0 0 10px rgba(255,201,60,.8)); }

.star.earned::before {         /* ray flash */
  content: ""; position: absolute; inset: -55%;
  background: conic-gradient(from 0deg, transparent 0 12deg, rgba(255,201,60,.5) 12deg 18deg,
              transparent 18deg 42deg, rgba(255,201,60,.5) 42deg 48deg, transparent 48deg 90deg);
  border-radius: 50%;
  animation: ray-flash .6s ease-out both;
}
@keyframes ray-flash { 0% { transform: scale(.2) rotate(0); opacity: 1; }
                       100% { transform: scale(1.5) rotate(45deg); opacity: 0; } }
```

### 5.7 Button Squash-and-Stretch
Every wooden button. Press = squash (via `:active`, instant feel), release = stretch-rebound keyframe (JS adds `.released` on `pointerup`, removes on `animationend`).

```css
.btn-wood:active { transform: scale(.94, .9); }
@keyframes btn-release {
  0%   { transform: scale(.94, .9); }
  40%  { transform: scale(1.07, 1.09); }
  70%  { transform: scale(.985, .975); }
  100% { transform: scale(1); }
}
.btn-wood.released { animation: btn-release .22s ease-out; }
```

### 5.8 Day-Sky Gradient Shift (the storytelling beat)
Two stacked gradient layers in `.field`; dusk cross-fades over the morning as level time elapses. Driven by the CSS animation clock so pause is free (`animation-play-state`), duration set from JS to the level length:

```css
.sky-day  { position: absolute; inset: 0; z-index: 0;
            background: linear-gradient(#C4EAF8, var(--c-sky-day) 55%, #D8EFC9); }
.sky-dusk { position: absolute; inset: 0; z-index: 0; opacity: 0;
            background: linear-gradient(#FDD9A0, var(--c-sky-dusk) 60%, #E8A56B);
            animation: dusk-in var(--level-secs, 120s) linear forwards; }
@keyframes dusk-in { 0% { opacity: 0; } 55% { opacity: 0; } 100% { opacity: 1; } }
.game.paused .sky-dusk { animation-play-state: paused; }
```

Nothing happens for the first 55% (a calm morning), then the warm dusk fades up — players learn "orange sky = hustle" within one level. Final 10s: HUD timer joins with its ⚠️ state.

---

## 6. Audio Direction — WebAudio Synthesis

**Rules:** create `AudioContext` on first user gesture; one `master` GainNode (0.5) → destination; every SFX ≤ 400ms except fanfare; all envelopes ramp to 0.0001 before `stop()` (no clicks); mute toggle just sets `master.gain`.

Shared helper the whole SFX set is built on:

```js
let AC, master;
function audioInit() {                     // call on first pointerdown
  AC = new (window.AudioContext || window.webkitAudioContext)();
  master = AC.createGain(); master.gain.value = 0.5; master.connect(AC.destination);
}
function blip({ type='sine', f0=440, f1=f0, dur=0.1, vol=0.3, delay=0 }) {
  const t0 = AC.currentTime + delay;
  const o = AC.createOscillator(), g = AC.createGain();
  o.type = type;
  o.frequency.setValueAtTime(f0, t0);
  o.frequency.exponentialRampToValueAtTime(Math.max(f1, 1), t0 + dur);
  g.gain.setValueAtTime(0, t0);
  g.gain.linearRampToValueAtTime(vol, t0 + 0.008);              // 8ms attack
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);        // exp decay
  o.connect(g).connect(master); o.start(t0); o.stop(t0 + dur + 0.02);
}
function noise({ dur=0.3, vol=0.2, fc0=1200, fc1=400, delay=0 }) {   // filtered noise (water)
  const t0 = AC.currentTime + delay;
  const buf = AC.createBuffer(1, AC.sampleRate * dur, AC.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  const src = AC.createBufferSource(); src.buffer = buf;
  const f = AC.createBiquadFilter(); f.type = 'lowpass';
  f.frequency.setValueAtTime(fc0, t0);
  f.frequency.exponentialRampToValueAtTime(fc1, t0 + dur);
  const g = AC.createGain();
  g.gain.setValueAtTime(vol, t0);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  src.connect(f).connect(g).connect(master); src.start(t0);
}
```

### The 8 SFX

| # | SFX | Recipe (copy-paste calls) | Character |
|---|-----|---------------------------|-----------|
| 1 | **Plant** | `blip({type:'sine', f0:180, f1:90, dur:0.08, vol:0.25})` | soft "thup" into soil — pitch drop = downward motion |
| 2 | **Water** | `noise({dur:0.3, vol:0.18, fc0:1400, fc1:350})` | filtered noise sweep = splash/pour, no oscillator at all |
| 3 | **Harvest** | `blip({type:'triangle', f0:300, f1:900, dur:0.09, vol:0.3})` then `blip({type:'triangle', f0:600, f1:1200, dur:0.06, vol:0.2, delay:0.05})` | double rising pluck — "pop-pop" matches §5.1 |
| 4 | **Coin** | `blip({type:'square', f0:988, f1:988, dur:0.07, vol:0.12})` then `blip({type:'square', f0:1319, f1:1319, dur:0.22, vol:0.12, delay:0.07})` | B5→E6, the classic arcade coin interval; square at low vol = chiptune sparkle. Fire on coin *arrival* (§5.2), pitch +30 cents per coin in a stack |
| 5 | **Order complete** | triangle arpeggio: `[523.25, 659.25, 783.99].forEach((f,i)=>blip({type:'triangle', f0:f, f1:f, dur: i===2?0.28:0.1, vol:0.25, delay:i*0.09}))` | C5-E5-G5 major — bright "ka-ching" resolution |
| 6 | **Order failed** | `blip({type:'sawtooth', f0:294, f1:262, dur:0.18, vol:0.12})` then `blip({type:'sawtooth', f0:262, f1:220, dur:0.3, vol:0.10, delay:0.18})` — route both through a lowpass at 900Hz if adding one line: gentle, never punishing | two drooping slides = tiny sad trombone; quiet on purpose |
| 7 | **Level-win fanfare** | `[[523,0,.12],[523,.12,.12],[659,.24,.12],[784,.36,.18],[1047,.54,.5]].forEach(([f,d,dur])=>{ blip({type:'triangle', f0:f, f1:f, dur, vol:0.28, delay:d}); blip({type:'square', f0:f*1.005, f1:f*1.005, dur, vol:0.08, delay:d}); })` | C-C-E-G-C̄ bugle call, ~1.05s; detuned square layer adds shimmer. Star pops in §4.5 reuse SFX 5 pitched +0/+4/+7 semitones |
| 8 | **Button click** | `blip({type:'sine', f0:600, f1:520, dur:0.035, vol:0.15})` | 35ms tick — felt, not heard. Never on hover |

### Music: deliberately skipped — ambient bed instead

**Decision: no looped melody.** Rationale: (a) synth loops built from bare oscillators turn grating within minutes in a genre with 3–8 minute levels and heavy repeat play; (b) melodic music fights the 8 pitched SFX for the same narrow frequency space; (c) silence makes the fanfare land harder. Instead, a **generative ambient bed** (its own gain node, `Ambient sounds` toggle in Settings):

- **Birdsong:** every 8–20s (random), 2–3 quick sine chirps: `blip({type:'sine', f0:2400+rand(800), f1:3200+rand(600), dur:0.09, vol:0.06, delay:i*0.12})`. Suppressed during the last 25% of the level (dusk — birds go quiet: storytelling through absence).
- **Wind:** every ~30s, one slow `noise({dur:2.5, vol:0.03, fc0:500, fc1:250})` swell.
- **Dusk cricket:** in the final 25%, a single 4.2kHz sine pulsing 4×/s for 1s, vol 0.04, every ~15s.
- Pause ambient when `document.hidden` or game paused.

---

## 7. Accessibility

**Contrast (WCAG AA, verified pairs — re-check with a contrast tool if any hex is tweaked):**
- `--c-text` #3B2A1A on `--c-paper`/`--c-panel`: ~11:1 ✅ body text
- `--c-text-inv` #FFF8EC on `--c-panel-dark` #33261A: ~11:1 ✅ HUD text
- `--c-gold` #FFC93C on `--c-panel-dark`: ≈8:1 ✅ HUD numerals (large + bold anyway)
- `--c-danger-ink` #B93B2A / `--c-success-ink` #2E6B22 on paper: ≥4.5:1 ✅ — **always use the `-ink` tokens for text**; the brighter `--c-danger`/`--c-success` are fills only, and fills always carry an icon or label
- `--c-text-inv` on `--c-wood` #B07A45 buttons: ≈4.6:1 — passes at button size (20px/600); add `text-shadow: 0 1px 0 var(--c-wood-dark)` for extra edge
- Never: gold text on paper (≈1.6:1 — gold is for dark surfaces and shapes only)

**Hit targets:** every interactive element ≥ **44×44px** (`min-width/min-height: 44px`): toolbar buttons 56px, plots ≥48px (§2.1 floor — grid size capped per level so 380px viewports never shrink below it), HUD icons 44px, map nodes 56px, toggle rows are fully-tappable 56px rows.

**Reduced motion:**

```css
@media (prefers-reduced-motion: reduce) { :root { --rm: 1; } }
/* Settings "Reduce motion: On" also sets data-rm="1" on <html>; "Off" forces data-rm="0". */
html[data-rm="1"] .cloud, html[data-rm="1"] .chicken,
html[data-rm="1"] .crop-sway, html[data-rm="1"] .fx-coin { animation: none !important; }
```

Behavior map: decorative loops (clouds, chicken, sway, petal drift) **off**; coin arc → cash number counts up with a 150ms opacity blip; ready pulse → static 3px gold outline + ✨ badge (already present); ticket shake → static red outline + ⚠️ icon (already present); star burst → simple 200ms fades in sequence; sky shift **kept** (below flash-risk thresholds, informationally useful) unless `data-rm="1"`, then it steps at 55%/80%/100%. State-change transitions ≤150ms are kept (they communicate, not decorate).

**Playable without color alone** (every color signal has a shape/text twin):
- Ready plot: gold pulse **+ ✨ badge + raised scale**
- Watered soil: darker **+ 💧 badge** in plot corner
- Patience: bar length **+ ❤️→😟 face swap + numeric % on focus + shake/outline at low**
- Timer warning: color shift **+ ⚠️ icon + final-10s tick SFX**
- Locked levels: desaturation **+ 🔒**
- Star slots: earned ⭐ vs hollow ☆ (shape, not hue)
- Goal bar: fill **+ "240/350" text label inside**

**Keyboard & screen reader:** full keyboard play — arrows move a visible plot cursor (`outline: 3px solid var(--c-water); outline-offset: 2px`, same style as `:focus-visible` everywhere), Enter/Space acts with selected tool, `1–6` select seeds, `W`/`H` water/harvest, `Esc` pause. Plots are `<button aria-label="Plot 3, carrot, ready to harvest">` (label updated on state change). One polite `aria-live` region announces order events ("Order complete, +40 coins"). Sound toggles are real `<button aria-pressed>`.

---

## 8. Whimsy List — 6 Delighters

Each is ≤ a dozen lines of code, transforms/opacity only, disabled under reduced motion, and never blocks input.

1. **Chicken wander (title + field edge).** 🐔 strolls the grass strip: JS picks a random x every 4–9s, CSS `transition: transform 3s linear` walks it there (flip with `scaleX(-1)` when heading left), then a 2-frame "peck" (rotate 20deg at the beak, twice) before the next stroll. Click it: startled hop (`translateY(-14px)`, 250ms) + a soft cluck (`blip({type:'square', f0:880, f1:440, dur:0.12, vol:0.1})`) + one 🥚 floater. Pure joy, zero mechanics.
2. **Cloud drift.** Three CSS clouds (white `border-radius:50%` blobs, 3 overlapping divs each, `opacity:.9`) crossing the sky at 70s/95s/120s linear infinite at different heights/scales — free parallax depth. They warm-tint at dusk automatically because the dusk layer fades over them.
3. **Crop idle sway.** Growing crops (stages 1–3) sway ±2.5deg, 3s ease-in-out infinite alternate, `transform-origin: 50% 90%`, desynced via `animation-delay: calc(var(--i) * -0.35s)` (set `--i` per plot). The field breathes like a real one.
4. **Scarecrow hat-tip.** A 🎩+😐 scarecrow (two stacked spans) stands off-grid beside the field. On a 3+ harvest combo, the hat pops up 10px with a rotate wiggle (400ms, `--ease-pop`) and the face swaps to 😄 for 2s. Combo feedback that isn't another popup.
5. **Victory tractor.** On level complete, before the results panel drops: 🚜 drives across the bottom of the screen (translateX, 1.4s ease-in-out) towing the day's top-earning crop emoji ×3 bouncing behind it at staggered delays. Ends off-screen as the panel lands.
6. **Seasonal map bands + title barn easter egg.** Level map shifts with progress: 1–5 spring (grass + drifting 🌸 petals), 6–10 summer (deeper green, slow ☀️ shimmer), 11–15 autumn (`--c-grass` blends toward #B98A3E, falling 🍂), 16–20 winter (pale ground, drifting ❄, snow-capped fence caps via a white `border-top`). Bonus egg: click the title-screen barn 5× fast → 8 random farm emoji rain down (pooled floaters) + a hidden fanfare in a major 6th. No reward, just a secret smile.

---

## Appendix A — Performance Budget (Technical Artist sign-off)

| Budget item | Cap |
|---|---|
| Plot grid | ≤ 8×6 = 48 plot buttons, `contain: layout paint` each |
| Concurrent pooled particles (coins/floaters/✨) | 12 nodes, reused, never created in gameplay loops |
| Ambient decorative animators (clouds, chicken, scarecrow) | ≤ 6 nodes |
| Animated properties | `transform`, `opacity`, `box-shadow` only on ≤ 48 pulse nodes (pulse is the one allowed shadow anim; if profiling shows paint cost on low-end, swap to a pre-drawn glow `::after` fading opacity) |
| rAF loops | exactly 1 (game tick); all cosmetic motion is CSS |
| `will-change` | only on `.fx-coin` pool nodes |
| Layout thrash | batch all `getBoundingClientRect` reads at spawn-time, before writes |
| File weight | inline SVGs ≤ 3KB total; zero images, zero fonts, zero network |

## Appendix B — Build Order for the Developer

1. Tokens + layout shell (§1, §2) → 2. Plot grid + emoji stage renderer (§3.2) → 3. HUD + tickets with SVG background (§3.3B) → 4. Screens/overlays (§4) → 5. Juice pass (§5, in listed order — harvest pop first, it's the core loop feel) → 6. Audio (§6, helper first, then table top-to-bottom) → 7. Accessibility pass (§7 checklist) → 8. Whimsy (§8) last, budget-permitting — but never ship without #1 and #2; they're the soul.
