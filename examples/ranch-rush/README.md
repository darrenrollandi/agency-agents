# Ranch Rush

A complete, self-contained farm time-management game — plant, water, harvest,
process, and fulfill customer orders against a day timer across a 20-level
career, plus an unlockable Endless "Free Play" mode.

Everything lives in a single file: **`index.html`**. There are zero external
requests (no CDNs, fonts, or images — only emoji, CSS, and inline SVG), so it
works by double-clicking the file and opening it straight from `file://`.

## How to play

1. Open `index.html` in any modern browser (Chrome, Firefox, Safari, Edge).
2. From the title screen, choose **New Game** to start the 20-day career, or
   **Free Play** for Endless mode (unlocks after clearing Day 10).
3. Each day: click a seed in the tray, then click empty plots to plant. Click
   glowing plots to water or harvest them. Click animals to feed/collect, and
   machines to load/collect. Click a glowing order ticket to fulfill it —
   goods are deducted automatically and coins fly to your wallet. Reach the
   goal before the timer runs out to earn 1–3 stars.
4. Between days, visit the **Ranch Shop** to buy animals, machines, and
   upgrades with your earnings.

### Controls
- **Mouse/touch**: full point-and-click/tap play, including on 380px-wide
  phones (every tap target is ≥44×44px).
- **Keyboard (bonus layer, never required)**: `1–8` select a seed, `Esc`
  pauses/closes the current panel, `M` toggles mute, `S` opens/closes the
  Market stand. All buttons are real `<button>` elements, so `Tab`/`Enter`/
  `Space` work everywhere natively.
- **Accessibility**: every interactive element has an ARIA label that updates
  with its state, order events are announced via a polite live region, no
  state is ever conveyed by color alone (icons/text always back up color),
  and `prefers-reduced-motion` (or the in-game toggle) disables decorative
  animation while keeping state-communicating transitions.

## How saving works

Progress is stored in `localStorage` under `ranchrush_save_v1`, with a
rotating backup at `ranchrush_save_v1_bak`. The save is a small versioned
JSON blob (`schemaVersion`) containing: career unlocks and per-level star
records, wallet, purchased animals/machines/upgrades, settings, Endless-mode
bests, and lifetime stats.

- **Corruption-proof**: if the primary save can't be parsed, the raw blob is
  preserved under `ranchrush_save_v1-corrupt` for forensics, the game falls
  back to the backup (or a fresh profile if that's also missing/corrupt), and
  it never crashes.
- **Transactional attempts**: your wallet is snapshotted the moment a day
  starts. Winning a day commits the new wallet balance, star rating, and
  stats. Failing, quitting to the map, or closing the tab mid-day rolls
  everything back to the snapshot — you can only ever lose progress made
  *during* that one attempt, never anything already committed.
- **Write points**: a day starting, a day ending, every shop purchase, every
  settings change, and `beforeunload`/tab-hidden all flush the save.
- **Settings screen** (gear icon) lets you toggle sound and reduced motion,
  hold-to-confirm a full save reset, and copy/paste a base64 save code to
  move progress between browsers or machines.

## Verification

Automated Playwright checks (headless Chromium) confirmed on this build:
zero console/page errors on load, New Game → Level 1 → planting a seed
changes plot state, and reloading the page after that offers **Continue**
on the title screen — plus an extended pass covering a full organic level-1
win (star reveal, save commit, level-2 unlock), pause/resume timer freeze,
the Market stand, corrupt-save recovery, save-code export/import, the
hold-to-confirm reset flow, and mobile-viewport layout at 380px.

---

Built by the agency-agents game-development division.
