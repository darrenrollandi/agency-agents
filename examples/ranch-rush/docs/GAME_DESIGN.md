# RANCH RUSH — Game Design Document

**Version:** 1.0 (implementation-ready)
**Date:** 2026-07-17
**Authors:** GameDesigner (lead), LevelDesigner (playfield, pacing, career curve), NarrativeDesigner (characters, flavor, customer voice)
**Target:** Single self-contained HTML file. Vanilla JS, DOM/canvas hybrid, emoji/CSS/SVG sprites only, WebAudio-synthesized sound. 60 fps.

**Changelog**
- v1.0 — Initial complete spec. All numbers tuned via the throughput model in §12 (no placeholders).

---

## 1. Vision & Design Pillars

An original homage to the classic farm time-management genre: plant, water, harvest, process, and fulfill customer orders against a day timer. One pair of hands, ten things ripening at once.

**Pillars** (every decision below is measured against these):

1. **Every second has a job.** The fun is queue management — there is always a best next click, and finding it feels smart.
2. **Readable at a glance.** Every entity broadcasts its state with an emoji + one color + one motion. No tooltips required to play.
3. **Kind pressure.** Timers push, but failure is cheap: instant retry, nothing persistent lost, no RNG spikes.
4. **Mastery snowball.** Each unlock adds a *verb combination* (feed the cow → churn the milk → fill Gus's order), not just bigger numbers.

**Fun hypothesis:** chaining 3+ actions without a wasted second (harvest → load oven → fulfill ticket while the coins are still flying) is intrinsically satisfying. If that chain doesn't feel good in the greybox, nothing else matters.

**Definition of "broken" (for tuning passes):** a level is broken if (a) the 1★ goal needs > 60% of expert throughput (§12), (b) any order can request a good the player cannot currently produce, or (c) the player can reach a state with $0, no seeds affordable, no crops growing, and no inventory (deadlock — see §17 breaker).

---

## 2. Core Loops

### Moment-to-moment loop (~30 seconds)
- **Action:** Click a seed in the tray → click empty plots to plant → water the 💧 plots → harvest bouncing ready crops → click a glowing order ticket to fulfill (goods auto-deduct) → collect animal products / reload machines in the gaps.
- **Feedback:** every click lands within 1 frame — pop, fly-to-HUD, coin plinks, stamp (§16).
- **Reward:** the goal bar visibly climbs on every sale; tips spark when you're fast.
- **Decision:** *which* of the 3–6 currently-legal clicks earns the most per second right now (order about to expire? cow hungry? oven idle?).

### Session loop (one career level, 2–5 minutes)
- **Goal:** earn the level's cash target before the day timer ends (goal = **gross coins received** during the level; seed spend does not reduce the bar — it only drains the wallet).
- **Tension:** order patience timers vs. crop grow timers vs. one pair of hands. From L6, ready crops wilt if ignored.
- **Resolution:** target reached = day won (timer keeps running — overshoot earns 2★/3★). Timer ends below target = day lost, instant retry.

### Long-term loop (career, ~90–120 minutes to credits)
- **Progression:** 20 levels unlock 8 crops, 3 animals, 3 machines, 6 plots (4→10), and a 7-item upgrade shop, on a fixed schedule (§6).
- **Retention hooks:** star-chasing (60 stars total, late 3★s demand near-expert play, §12), Endless Mode unlocked at L10 with a persistent best score, and lifetime stats (orders served, coins earned).

---

## 3. Playfield Layout & Entity Budget *(LevelDesigner)*

One static screen — no scrolling, no avatar walking. Direct manipulation only. The eye-flow argument of the layout: **top-left wallet → top order rail → center field**, so the player's scan path matches the priority order (money state → demand → supply).

```
┌──────────────────────────────────────────────────────────┐
│ HUD: 🪙 wallet │ GOAL BAR ▓▓▓░░ │ ⏱ timer │ ★★☆ pips     │
├──────────────────────────────────────────────────────────┤
│ ORDER RAIL: [🎩 ticket] [☕ ticket] [🍳 ticket] [ + ]     │
├────────────┬────────────────────────────────┬────────────┤
│ PADDOCK    │        FIELD GRID              │ MACHINE    │
│ 5 stalls   │        2 rows × 5 plots        │ SHELF      │
│ 🐔🐄🐑 +/+  │        (locked plots show ⛓)   │ 🥖 🧀 🫙   │
├────────────┴────────────────────────────────┴────────────┤
│ INVENTORY CHIPS: 🌾×3 🥚×1 🥛×2 …          🧺 Market      │
│ SEED TRAY: [🌾][🥕][🌽][🍅][🍓][🌻][🎃][🍇]  (1–8 keys)   │
└──────────────────────────────────────────────────────────┘
```

- Plots unlock in a fixed compact pattern: start 2×2 (top-left of grid), then fill left→right, top row first, so the field never has holes.
- Minimum layout width 360 px (portrait phones): paddock and machine shelf collapse to horizontal strips above the seed tray. All tap targets ≥ 44×44 px.
- Critical-path readability: at any moment, the highest-value click is animated (ready = bounce, fulfillable ticket = green glow, hungry = bubble). Nothing important is ever conveyed by color alone (§17).

**Hard entity budget (60 fps guardrail):**

| Entity | Max simultaneous |
|---|---|
| Plots | 10 |
| Animals | 5 |
| Machines | 3 |
| Order tickets | 4 |
| Canvas particles (pooled) | 64 |
| Floating text (pooled DOM) | 8 |
| Total interactive DOM nodes | ~80 |

Implementation: DOM (CSS transforms/opacity only) for all interactive entities; one full-screen `<canvas>` overlay for particles; fixed 100 ms logic tick + rAF render with interpolation; all timers run on game-time (pause-safe). WebAudio: one `AudioContext`, master `GainNode`, oscillator+envelope one-shots (no assets).

---

## 4. Player Verbs & Input Model

**Primary input: single click/tap. No drag, no double-click, no hold required anywhere.** Keyboard is a bonus layer, never required.

**Seed selection model:** the seed tray is always visible. Clicking a seed selects it (tray chip lifts + highlights). Clicking any empty plot plants the selected seed instantly. Level 1 starts with Wheat pre-selected so the very first plot click already works.

### Click behavior by object and state

| Object | State | Click does | Denied-click feedback |
|---|---|---|---|
| Empty plot | — | Plants selected seed (if wallet ≥ seed cost) | Wallet flashes red + "need $N" float |
| Plot | Growing, no water need | Nothing (shows remaining-time tooltip for 1.5 s, sprout wiggles) | — |
| Plot | 💧 Awaiting water | Waters it — growth resumes (Big Watering Can upgrade also waters orthogonal neighbors awaiting water) | — |
| Plot | ✨ Ready (bouncing) | Harvests 1 unit → flies to inventory | — |
| Plot | 🥀 Wilted (L6+, §17) | Clears plot instantly, refunds full seed cost | — |
| Animal | Idle/producing | Pet: heart particle, tiny squeak (pure juice, no effect) | — |
| Animal | 🍽 Hungry (bubble) | Feeds it — consumes 1 feed item from inventory, production resumes | Feed chip in inventory flashes red if missing |
| Animal | Product ready (bubble shows product) | Collects product → inventory | — |
| Machine | Idle | Loads recipe if all inputs in inventory (auto-consumed), starts processing | Recipe popover, missing inputs outlined red for 2 s |
| Machine | Working | Shows time-left ring tooltip | — |
| Machine | Done (lid bouncing) | Collects output → inventory | — |
| Order ticket | Fulfillable (green glow) | Fulfills: goods auto-deduct, fly to ticket, PAID stamp, payout + tip | — |
| Order ticket | Not fulfillable | Pins missing goods: red outline on the needed chips/tray for 2 s | — |
| Market stand 🧺 | — | Opens sell panel: click a stack = sell 1 at base value; "Sell all" button per stack | — |
| Pause ⏸ / Esc | — | Full freeze (all timers stop), resume/retry/give-up menu | — |

### Keyboard bonus layer
`1–8` select seed · `Space` or `P` pause · `S` open/close market panel · `M` mute · `Esc` close panel / pause. No action is keyboard-only.

---

## 5. Crops (8 — hard cap)

Growth is 3 visual stages (🟤 seeded → 🌱 sprout → full emoji "ready"). **Watering rule:** water-crops pause at the end of stage 1 and show 💧 until watered once; watering resumes growth (water response time is *not* part of grow time). Each harvest yields 1 unit. Ready crops never expire in L1–5; from L6 they wilt 40 s after becoming ready (§17).

| Crop | Emoji | Seed cost | Grow time per stage (s) | Total (s) | Sell value | Unlock | Needs water |
|---|---|---:|---|---:|---:|---|---|
| Wheat | 🌾 | 5 | 2 + 2 + 2 | 6 | 12 | L1 | No |
| Carrot | 🥕 | 8 | 3 + 3 + 3 | 9 | 20 | L2 | No |
| Corn | 🌽 | 12 | 4 + 4 + 4 | 12 | 30 | L4 | **Yes** |
| Tomato | 🍅 | 15 | 5 + 5 + 5 | 15 | 40 | L6 | **Yes** |
| Strawberry | 🍓 | 20 | 6 + 6 + 6 | 18 | 55 | L9 | **Yes** |
| Sunflower | 🌻 | 25 | 7 + 7 + 7 | 21 | 65 | L11 | No |
| Pumpkin | 🎃 | 30 | 8 + 8 + 8 | 24 | 80 | L13 | **Yes** |
| Grapes | 🍇 | 40 | 10 + 10 + 10 | 30 | 110 | L16 | **Yes** |

**Rationale:** profit-per-plot-second rises monotonically with unlock order (wheat $1.17/s → grapes $2.33/s net), so new crops are always worth adopting. Water-crops pay a small premium per second over the nearest no-water crop (e.g., strawberry 1.94 vs. sunflower 1.90) to compensate for the extra click; sunflower exists as the deliberate "low-attention" choice when the player's hands are busy with machines.

---

## 6. Animals (3 — hard cap)

Animals live in the paddock (5 stalls max, any mix). Production loop: cycle timer runs → product-ready bubble → click collects. **Feed rule:** feed-animals go 🍽 hungry at the start of each cycle and pause until fed (1 feed item from inventory). Animals never die, never produce waste; hunger just pauses them. Bought in the between-level Ranch Shop only (§14).

| Animal | Emoji | Purchase cost | Product (sell value) | Production interval | Feed per cycle | Unlock |
|---|---|---:|---|---:|---|---|
| Chicken | 🐔 | 60 | Egg 🥚 ($18) | 12 s | None (free-range) | L3 — **first one is a free gift from Bea** |
| Cow | 🐄 | 150 | Milk 🥛 ($35) | 18 s | 1× Wheat 🌾 | L7 |
| Sheep | 🐑 | 260 | Wool 🧶 ($60) | 24 s | 1× Carrot 🥕 | L13 |

**Rationale:** chicken is the zero-maintenance tutorial animal (income floor while learning). Cow and sheep create *routing* decisions — a harvested wheat is either $12 now or a $35 milk in 18 s — which is the genre's core resource tension. Sheep's wool is the high-value raw good that never needs a machine (payout valve for busy late-game hands).

---

## 7. Machines (3 — hard cap)

One of each machine max, on the machine shelf. Loading auto-consumes inputs from inventory and starts the timer; output waits in a 1-item buffer until collected (no input queue — collect-then-reload is one click each, and the juggle is the game). Machine Grease upgrade (§14) cuts processing time 20%.

| Machine | Emoji | Cost | Recipe (inputs → output) | Output sell value | Processing time | Unlock |
|---|---|---:|---|---:|---:|---|
| Bread Oven | 🥖 | 200 | 2× Wheat 🌾 + 1× Egg 🥚 → Bread 🍞 | 55 | 8 s | L5 |
| Cheese Churn | 🧀 | 350 | 2× Milk 🥛 → Cheese 🧀 | 90 | 10 s | L8 |
| Jam Pot | 🫙 | 500 | 3× Strawberry 🍓 → Jam 🫙 | 220 | 12 s | L10 |

**Processing premium:** Bread +31% over input base value (42→55), Cheese +29% (70→90), Jam +33% (165→220) — before the order premium and tips, which stack on top. Machines are strictly optional for 1★ but are the backbone of 3★ pace and of Gus's and Bea's high-value orders.

### Goods price index (every sellable, base market value)
🌾 12 · 🥕 20 · 🌽 30 · 🍅 40 · 🍓 55 · 🌻 65 · 🎃 80 · 🍇 110 · 🥚 18 · 🥛 35 · 🧶 60 · 🍞 55 · 🧀 90 · 🫙 220

---

## 8. Order System

Orders are the primary sale channel (base value × 1.35 + tips); the Market stand is the pressure valve (base value, always available, also counts toward the goal).

### Generation
- **Concurrency cap:** 2 tickets (L1–4), 3 (L5–10), 4 (L11–20 and Endless).
- **Spawn timing:** first ticket at t = 2 s. Whenever tickets < cap, a new one spawns after a delay *D*: L1–5: 14 s · L6–10: 12 s · L11–15: 10 s · L16–20: 8 s.
- **Composition:** 1–3 line items, each a good with quantity 1–4 (quantity weights 1:40 / 2:35 / 3:20 / 4:5). Item-count weights by band:

| Band | 1 item | 2 items | 3 items | Category weights (crop / animal / machine goods) |
|---|---:|---:|---:|---|
| A (L1–4) | 50% | 40% | 10% | 80 / 20 / 0 |
| B (L5–8) | 40% | 40% | 20% | 55 / 25 / 20 |
| C (L9–12) | 30% | 40% | 30% | 50 / 25 / 25 |
| D (L13–16) | 25% | 40% | 35% | 45 / 27 / 28 |
| E (L17–20) | 20% | 40% | 40% | 40 / 28 / 32 |

- **Producibility guard (hard rule):** the generator only picks goods the player can currently produce — unlocked crops, products of *owned* animals, outputs of *owned* machines. No exceptions.
- **Value clamp (anti-RNG-spike):** total base value of a ticket is clamped per band — A: $20–60 · B: $40–140 · C: $80–260 · D: $140–420 · E: $200–600. Reroll up to 6 times, then trim the cheapest line item until in range.
- **First ticket of every level** is always a single-line raw-crop order (warm-up guarantee).
- RNG is seeded per attempt (retries get a fresh seed).

### Payout formula
```
payout = ceil(totalBaseValue × 1.35 / 5) × 5        // order premium, rounded up to $5
tip    = +25% of payout if fulfilled with ≥ 60% patience remaining
         +10% of payout if fulfilled with ≥ 30% patience remaining
         (0 below 30%; tip rounded to nearest $1)
streak = after 3 consecutive fulfillments with no expiry, a 🔥 badge grants
         +5% on all order payouts until any ticket expires
```

### Patience timer
```
P = clamp(75 − 1.5 × level, 45, 75) seconds        // L1: 73→∞ (see below) … L20: 45
× 1.5   if the ticket contains any machine good
× customer modifier (§15)
× 1.2   if Coffee Station upgrade owned
```
- **L1–2: patience is infinite** (bar shown full; tips still timed against nominal P = 75 s).
- **Expiry:** the ticket sighs and slides away. **No cash penalty** — the costs are the lost sale and the streak reset (and a heart in Endless). The slot refills after the normal spawn delay.

### Fulfillment
Click a glowing ticket → all required goods auto-deduct from inventory, fly to the ticket, PAID stamp, coins fly to wallet. Partial delivery is not a mechanic (keeps tickets binary-readable).

---

## 9. Career Mode — 20 Levels

Structure: **Level Select (map path of 20 nodes) → Ranch Shop → play the day → Results (stars) → Shop → next node.** Unlocks listed below are available *from the start of* that level. Plots are granted free (no purchase) to keep the difficulty curve deterministic; shop items are pure acceleration.

Stars: **1★ = goal reached · 2★ = goal × 1.35 · 3★ = goal × 1.75** (rounded to nearest $5). Values below are final.

| Lv | Time (s) | Goal 1★ | 2★ | 3★ | Unlocks at level start | Twist / note |
|--:|--:|--:|--:|--:|---|---|
| 1 | 120 | 60 | 80 | 105 | Wheat 🌾, 4 plots, Market stand | Scripted onboarding (below). Infinite patience. |
| 2 | 120 | 120 | 160 | 210 | Carrot 🥕 | Infinite patience. Teaches crop choice. |
| 3 | 150 | 220 | 295 | 385 | 5th plot; Bea gifts a free Chicken 🐔; chickens buyable ($60) | First animal; collect-on-bubble taught by Bea's egg order. |
| 4 | 150 | 350 | 475 | 615 | Corn 🌽 — first water crop | 💧 tutorial beat: first corn plot triggers a one-time "water me" pointer. |
| 5 | 180 | 640 | 865 | 1,120 | 6th plot; Bread Oven 🥖 buyable ($200); order cap → 3 | First machine; bread orders appear once oven owned. |
| 6 | 180 | 850 | 1,150 | 1,490 | Tomato 🍅; Big Watering Can in shop ($450) | **Wilt rule begins** (ready crops wilt after 40 s; full seed refund on clear). |
| 7 | 180 | 1,050 | 1,420 | 1,840 | Cow 🐄 buyable ($150); Fertilizer in shop ($600) | Feed loop taught: cow's 🍽 bubble asks for wheat. |
| 8 | 210 | 1,500 | 2,025 | 2,625 | 7th plot; Cheese Churn 🧀 ($350); Coffee Station in shop ($500) | Days lengthen to 3.5 min. |
| 9 | 210 | 1,900 | 2,565 | 3,325 | Strawberry 🍓; Cozy Barn in shop ($650) | — |
| 10 | 210 | 2,250 | 3,040 | 3,940 | Jam Pot 🫙 ($500); Machine Grease in shop ($700) | **Clearing L10 unlocks Endless Mode.** |
| 11 | 240 | 3,150 | 4,255 | 5,515 | 8th plot; Sunflower 🌻; order cap → 4 | Four tickets: triage becomes the skill test. |
| 12 | 240 | 3,400 | 4,590 | 5,950 | — | **Rush Hour:** spawn delay 10 s → 8 s this level only. |
| 13 | 240 | 3,900 | 5,265 | 6,825 | Pumpkin 🎃; Sheep 🐑 buyable ($260) | — |
| 14 | 240 | 4,400 | 5,940 | 7,700 | 9th plot | — |
| 15 | 270 | 5,200 | 7,020 | 9,100 | — | **Fair Day:** all tips +10 pp, patience ×0.85 this level only. |
| 16 | 270 | 5,900 | 7,965 | 10,325 | Grapes 🍇 | — |
| 17 | 270 | 6,650 | 8,980 | 11,640 | 10th plot (field complete) | — |
| 18 | 300 | 7,650 | 10,330 | 13,390 | — | **Banquet Orders:** 3-item weight doubled, value clamp +20%. |
| 19 | 300 | 8,050 | 10,870 | 14,090 | — | **Cold Snap:** machine-good order weight ×2, machine-good tickets pay ×1.25. |
| 20 | 300 | 8,500 | 11,475 | 14,875 | — | **Harvest Festival finale:** spawn 8 s, all customers appear, tips +5 pp; final 60 s is Golden Hour — all payouts ×1.25. |

### Level 1 onboarding script *(LevelDesigner + NarrativeDesigner)*
Three arrow-pointer beats, no walls of text, first success guaranteed:
1. t=0: wheat pre-selected, pointer on a plot — *"Tap a plot to plant."* (Planting all 4 is free-form.)
2. First wheat ready (t≈8 s): pointer — *"Tap to harvest!"*
3. First ticket (Dot 🧒, "2× 🌾", infinite patience) glows green when harvests land — *"Tap the ticket to sell."* Stamp, coins, done teaching.
A first-time player reaches $60 in **~70–85 s** (tutorial ~40 s + ~26 s of earning even at 30% of expert pace — see §12), satisfying the sub-90-second requirement. The timer overshoot then invites a 2★ chase in the same attempt.

### Pacing arc across the career *(LevelDesigner)*
Tension ramps in waves, not a line: new-toy levels (3, 5, 7, 10, 13, 16) are tuned ~3–5 points of required-efficiency *easier* than their neighbors so unlock days feel like a gift; twist levels (12, 15, 18, 19) are local spikes; 20 is the crescendo. See the e₁/e₃ columns in §12 — the required-efficiency curve is smooth and monotonic within ±3 points of the trend line.

---

## 10. Endless Mode ("Open Ranch")

Unlocked by clearing L10; full toolset once L20 is cleared (locked items simply absent until earned in career).

- **Setup:** everything you own in career (plots, animals, machines, upgrades). Starting day-wallet: $100 + $10 × total career stars.
- **Days:** rolling 180 s days, no money target. Day *n* modifiers: spawn delay = max(6, 12 − 0.5·(n−1)) s; patience × max(0.5, 1 − 0.04·(n−1)); order value clamp = Band E × (1 + 0.15·(n−1)); category weights = Band E.
- **Reputation hearts:** start with ❤×5. Each expired order −1 ❤; every 10 consecutive fulfillments +1 ❤ (cap 5). **0 hearts ends the run.**
- **Score:** total gross earned. Persisted: best score, best day reached, longest streak.
- Wilt rule always on; all career anti-frustration guards (§17) except the infinite-patience training wheels.

---

## 11. Ranch Shop & Upgrades (between levels only)

Animals, machines, and upgrades are bought **only** on the shop screen between days — keeps mid-level wallet logic transactional (§18) and gives the classic "spend your day's profit" beat. Seeds are the only mid-level purchase.

| Item | Cost | Effect | Available |
|---|---:|---|---|
| Chicken 🐔 (up to stall cap) | 60 | +1 egg producer | L3 |
| Cow 🐄 | 150 | +1 milk producer | L7 |
| Sheep 🐑 | 260 | +1 wool producer | L13 |
| Bread Oven 🥖 | 200 | Unlocks bread recipe | L5 |
| Cheese Churn 🧀 | 350 | Unlocks cheese recipe | L8 |
| Jam Pot 🫙 | 500 | Unlocks jam recipe | L10 |
| Big Watering Can | 450 | Watering also waters orthogonal thirsty neighbors | L6 |
| Fertilizer | 600 | All crops grow 10% faster | L7 |
| Coffee Station | 500 | All order patience +20% | L8 |
| Cozy Barn | 650 | Animal production 15% faster | L9 |
| Machine Grease | 700 | Machines process 20% faster | L10 |

(7 upgrade/build slots + 3 animal types = the whole shop; deliberately small so every purchase is felt.)

---

## 12. Economy Balance — The Math

### Model
**Expert throughput** R ($/s) assumes: plots never idle > 1 s, all goods sold, and a blended **revenue factor of 1.3×** base value (mix of order premium 1.35, average tips at fast play, and some base-value market dumping). **Efficiency e** = fraction of expert throughput a player actually captures. *"~70% efficiency play"* = a competent, non-optimizing player (e = 0.7).

Per-plot expert rate = (sell × 1.3) / (grow + handling), with handling = 2 s (plant+harvest clicks) or 3 s for water crops:

| Source | Expert rate ($/s) |
|---|---:|
| Wheat plot 1.95 · Carrot 2.36 · Corn 2.60 · Tomato 2.89 | |
| Strawberry 3.41 · Sunflower 3.67 · Pumpkin 3.85 · Grapes 4.33 | |
| Chicken 1.95 · Cow 2.53 · Sheep 3.25 | |
| Machine uplift at ~50% uptime, net of inputs: Oven +0.8 · Churn +1.0 · Jam Pot +1.5 | |

### Per-level check
"Expected build" = granted plots + best unlocked crop on all plots + the affordable purchase schedule (chicken ×2 by L5, cow L7, cow ×2 by L10, sheep L13, machines at unlock — affordability proven below). C₇₀ = 0.7 · R · t = what a 70%-efficiency player earns. **e₁ / e₃** = efficiency actually required for 1★ / 3★.

| Lv | Build (plots × crop + extras) | R ($/s) | t | C₇₀ ($) | Goal | Goal/C₇₀ | e₁ | e₃ |
|--:|---|--:|--:|--:|--:|--:|--:|--:|
| 1 | 4×wheat | 7.8 | 120 | 655 | 60 | 9% | 6% | 11% |
| 2 | 4×carrot | 9.5 | 120 | 794 | 120 | 15% | 11% | 19% |
| 3 | 5×carrot + 1🐔 | 13.8 | 150 | 1,446 | 220 | 15% | 11% | 19% |
| 4 | 5×corn + 1🐔 | 15.0 | 150 | 1,570 | 350 | 22% | 16% | 27% |
| 5 | 6×corn + 2🐔 + oven | 20.3 | 180 | 2,558 | 640 | 25% | 18% | 31% |
| 6 | 6×tomato + 2🐔 + oven | 22.0 | 180 | 2,776 | 850 | 31% | 21% | 38% |
| 7 | + 1🐄 | 24.6 | 180 | 3,094 | 1,050 | 34% | 24% | 42% |
| 8 | 7×tomato, + churn | 28.5 | 210 | 4,182 | 1,500 | 36% | 25% | 44% |
| 9 | 7×strawberry | 32.1 | 210 | 4,713 | 1,900 | 40% | 28% | 49% |
| 10 | + 2nd 🐄 + jam pot | 36.1 | 210 | 5,305 | 2,250 | 42% | 30% | 52% |
| 11 | 8×sunflower | 41.7 | 240 | 6,997 | 3,150 | 45% | 32% | 55% |
| 12 | same | 41.7 | 240 | 6,997 | 3,400 | 49% | 34% | 60% |
| 13 | 8×pumpkin + 🐑 | 46.3 | 240 | 7,782 | 3,900 | 50% | 35% | 61% |
| 14 | 9×pumpkin | 50.2 | 240 | 8,430 | 4,400 | 52% | 37% | 64% |
| 15 | same | 50.2 | 270 | 9,484 | 5,200 | 55% | 38% | 67% |
| 16 | 9×grapes | 54.5 | 270 | 10,302 | 5,900 | 57% | 40% | 70% |
| 17 | 10×grapes | 58.8 | 270 | 11,120 | 6,650 | 60% | 42% | 73% |
| 18 | same | 58.8 | 300 | 12,356 | 7,650 | 62% | 43% | 76% |
| 19 | same | 58.8 | 300 | 12,356 | 8,050 | 65% | 46% | 80% |
| 20 | same | 58.8 | 300 | 12,356 | 8,500 | 69% | 48% | 84% |

**Reading the table:** every 1★ goal sits at ≤ 69% of what a 70%-efficiency player earns (e₁ never exceeds 48%) — a 70% player clears every level, usually with time to spare. 2★ tracks ~e₁ × 1.35. 3★ is met at 70% efficiency through L15, then intentionally demands 70→84% — the mastery ceiling. Twist levels (12/15/18/19/20) shave or shift effective R by ≲ 10%, which the margins absorb; L19's ×1.25 machine payouts are approximately throughput-neutral.

**Worked example (L8):** 7 tomato plots at $2.89/s = $20.22/s, two chickens $3.90, one cow $2.53, oven+churn +$1.80 → R = $28.45/s. A 70% player earns 0.7 × 28.45 × 210 ≈ **$4,182** against a $1,500 goal — comfortable — while 3★ ($2,625) needs 44% of expert pace: brisk but honest.

### Cash-flow solvency (worst case: player only ever hits exactly 1★)
Net ≈ 55% of gross after seed/feed costs. Cumulative net minus the purchase schedule: after L4 ≈ $412 → buy oven $200 + 2nd chicken $60 (float $152) → after L6 ≈ $971 → cow $150 → after L7 ≈ $1,398 → churn $350 → after L9 ≈ $2,918 → jam pot $500 + 2nd cow $150 → after L12 ≈ $7,100 → sheep $260 trivially affordable at L13. **The expected build is always affordable even at minimum-star play; upgrades are gravy funded by 2★+ overshoot.** No level's tuning depends on any §11 upgrade.

---

## 13. Failure & Retry Rules

- **Fail state:** day timer reaches 0 with goal bar below 1★. "Sun sets" screen shows earned vs. goal bar, best-moment stat ("Biggest tip: $41"), then **Retry / Ranch Shop / Map**.
- **Retry:** instant, unlimited, free. Fresh order-RNG seed each attempt.
- **Transactional attempts:** wallet, inventory, and streak are snapshotted at level start; a failed/abandoned attempt rolls everything back to the snapshot. A successful day commits. Therefore **quitting mid-level (even closing the tab) loses at most that attempt** — never career progress, stars, purchases, or committed cash.
- **Give up** available from pause at any time (counts as a failed attempt, instant rollback).
- Beating a previously-cleared level with a better result updates stars/records; a worse result never downgrades them.

---

## 14. Anti-Frustration Features

1. **No wilting in L1–5.** Ready crops wait forever while learning. From L6, wilt takes 40 s (last 10 s telegraphed by a darkening plot ring) and clearing a 🥀 refunds the full seed cost — the penalty is time, never money.
2. **Producibility guard:** orders never request anything you can't currently make (§8).
3. **Value clamp + seeded rerolls:** no RNG order spikes (§8).
4. **Wallet floor:** at level start the wallet is topped up to a minimum $30 float if below it.
5. **Deadlock breaker:** if wallet < cheapest seed AND nothing growing AND inventory empty, a one-per-attempt "found coins under the porch" event grants $15 (with a charming toast). Condition is checked on the logic tick; by §1's "broken" definition this state must otherwise be unreachable.
6. **Infinite patience in L1–2**; patience floor of 45 s in career even at L20; machine-good tickets always get ×1.5 patience.
7. **No cash penalty on expiry** — lost opportunity and streak only.
8. **Full pause** freezes every timer, anywhere, including order patience.
9. **Feed/inputs pinning:** clicking anything you can't afford/fulfill highlights exactly what's missing for 2 s — the game always answers "why not?".
10. **Accessibility guards:** state never conveyed by color alone (💧/🍽/✨/🥀 icons always present); tap targets ≥ 44 px; `prefers-reduced-motion` swaps particles for fades; mute/music/SFX sliders.
11. **Kind economy:** animals never die, products never spoil, inventory is uncapped, market stand always buys at base value.

---

## 15. Narrative Wrapper *(NarrativeDesigner)*

Tone: warm, dry-witted, zero exposition dumps. Story lives in one-line letter snippets at band starts and in the customers themselves — each regular is also a mechanical archetype, so learning the cast *is* learning the order meta. Every line passes the "would a real person say this?" test.

### Cast (blurbs ≤ 2 sentences each)

- **Poppy Hale 👩‍🌾 (you).** A city spreadsheet-jockey who inherited Great-Aunt Maple's overgrown ranch and refuses to sell it to anyone who calls it "a land asset." Talks to the crops like coworkers, which — to be fair — they now are.
- **Bea 🐝 (neighbor, gifts the L3 chicken).** Retired beekeeper next door who has outlived three fences and every argument in town. Slips you a hen named Clementine "because a farm without gossip isn't a farm." *(Mechanics: patience ×1.4, 1–2 items, jam-biased when available.)*
- **Nina ☕ (food-truck owner).** Runs the pre-dawn coffee truck and speaks exclusively in half-sentences because the other half is already driving away. Tips like a saint if you match her speed. *(Patience ×0.8, 1–2 items, tips +10 pp.)*
- **Gus 🍳 (diner cook).** Gruff flat-top veteran whose compliments arrive disguised as complaints — "s'pose the cheese'll do." Orders processed goods almost exclusively. *(Patience ×1.2, machine-good weight ×2.)*
- **Mayor Butterfield 🎩.** Declares a "civic function" roughly weekly and orders like the county's watching, because it usually is. *(Patience ×1.0, 2–3 items, top tip tier pays +35% instead of +25%.)*
- **Dot 🧒.** Nine years old, owns a wagon and exact change, buys one strawberry at a time like it's a business meeting. The unofficial quality inspector of the entire ranch. *(Patience ×1.3, always 1 item ×1–2.)*

**Customer appearance weights** — Band A: Dot 35 / Nina 25 / Bea 25 / Gus 10 / Mayor 5 · B: 25/25/20/20/10 · C: 20/25/15/20/20 · D–E: 15/25/15/20/25.

### Flavor lines (shown on the band's first level-intro card)
- **L1–5:** *Aunt Maple's gate still squeaks, but the soil remembers her. Time to wake it up.*
- **L6–10:** *The diner put "local" on the menu and meant you. No pressure, says everyone, applying pressure.*
- **L11–15:** *The county fair committee "happened to be in the area." Committees don't happen to be anywhere.*
- **L16–20:** *Folks give directions using your ranch as the landmark now. Maple would've pretended not to smile.*
- **Endless:** *No targets today — just mornings, orders, and a gate that finally got oiled. Well. Mostly oiled.*

---

## 16. Feedback & Juice — 10 Specified Moments

All effects use pooled particles/DOM floats and WebAudio one-shots (synth params given; master gain 0.5, each one-shot through a short exponential decay envelope).

1. **Harvest pop.** Crop emoji scales 1→1.3→0 over 180 ms while a clone arcs (quadratic bezier, 400 ms) to its inventory chip; chip bumps +count. Audio: square wave 660→880 Hz sweep, 60 ms.
2. **Coin fly-to-HUD.** 3–7 🪙 particles bezier to the wallet over 500 ms with 40 ms stagger; wallet number count-ups; each landing plays a sine plink stepping up a pentatonic scale (C5-D5-E5-G5-A5).
3. **Order-complete stamp.** Green "PAID ✓" stamps in at 15° with a 120 ms overshoot scale, ticket flips away 300 ms later; customer emoji does a 2-frame hop. Audio: low thunk (sine 110 Hz, 80 ms) + paper flick (filtered noise burst 50 ms).
4. **Tip burst.** Golden "TIP +$X!" floats up 40 px; 12 confetti particles; triangle-wave sparkle arpeggio (3 notes, 90 ms each). Mayor's big tips add a tiny 🎩 doff.
5. **Watering splash.** 4 💧 particles; soil tile darkens for the rest of growth; crop does a 150 ms squash-and-stretch. Audio: band-passed white noise "psshh," 200 ms.
6. **Growth-stage tick.** Stage emoji swaps with a 120 ms scale bounce and a soft "toop" (sine 520 Hz, 40 ms) — quiet enough to layer ×10 plots.
7. **Machine rhythm.** Working machine shakes ±2 px in a loop with a low sine chug (90 Hz pulse at 2 Hz) and a conic-gradient progress ring; on DONE the lid pops 8 px with a 💨 puff and a bright ding (sine 1320 Hz, 200 ms).
8. **Patience escalation.** Ticket border pulses amber at 50% patience; at 25% it turns red with a soft tick-tock (alternating 800/600 Hz, 30 ms) and the customer emoji swaps 🙂→😅→😰. Expiry: ticket grays, sighs (descending 400→300 Hz), slides off.
9. **Goal reached.** Goal bar overfills gold with a shine sweep, one-shot fanfare arpeggio (C-E-G-C, saw wave, 400 ms), 20-particle confetti, and the sky tint warms — timer keeps running with a "BONUS ★ TIME" ribbon so the 2★/3★ chase reads instantly.
10. **Streak fire.** Third consecutive fulfillment slams a 🔥 badge onto the order rail (300 ms warm vignette flash at screen edges); every streak payout emits one ember particle; breaking it cracks the badge with a muted descending minor third.

(Results screen stars punch in one-by-one with noise-burst "cymbals" at 0/300/600 ms — same pooled systems, no new tech.)

---

## 17. Save System (first-class requirement)

**Storage:** `localStorage`, key `ranchrush_save_v1`, JSON < 2 KB, plus rotating backup `ranchrush_save_v1_bak` written before each successful overwrite. On parse failure: restore from backup, else fresh save (never crash). `schemaVersion` gates future migrations.

**Persists (committed state only):**

```json
{
  "schemaVersion": 1,
  "career": {
    "highestLevelUnlocked": 8,
    "levels": { "1": {"stars": 3, "bestEarned": 118}, "2": {"stars": 2, "bestEarned": 171} }
  },
  "wallet": 1240,
  "owned": {
    "animals": ["chicken", "chicken", "cow"],
    "machines": ["oven", "churn"],
    "upgrades": ["bigWateringCan", "coffeeStation"]
  },
  "endless": { "bestScore": 0, "bestDay": 0, "longestStreak": 0 },
  "stats": { "lifetimeEarned": 6841, "ordersServed": 92, "cropsHarvested": 431 },
  "settings": { "muted": false, "musicVol": 0.6, "sfxVol": 0.8, "reducedMotion": false }
}
```

- Plots are **derived** from `highestLevelUnlocked` (granted schedule, §9) — not stored, cannot desync.
- **Mid-level state is intentionally NOT persisted** (the "optional" allowance, declined): attempts are transactional (§13). Snapshot at level start lives in memory; success commits `wallet`, level record, and stats; fail/quit/tab-close discards deltas. Guarantee: **quitting mid-level loses at most that level attempt.**
- **Write points:** level start (commits any pending), level complete, every shop purchase, every settings change — debounced 500 ms — plus a best-effort `beforeunload`/`visibilitychange` flush of committed state only.

---

## 18. Performance & Implementation Notes (60 fps contract)

- Fixed 100 ms logic tick (all grow/patience/production timers in game-time; pause = tick suspension); rAF renderer interpolates progress bars/rings. Tab-hidden: logic suspends (no offline progress — it's a timed action game).
- DOM entities animate via `transform`/`opacity` only (compositor-only); zero per-frame layout reads; text updates batched to the logic tick.
- Single canvas overlay for particles: pooled array of 64, additive draw, cleared per frame; skipped entirely under `reducedMotion`.
- Audio: lazy-init `AudioContext` on first user gesture; every SFX ≤ 3 oscillator/noise nodes with scheduled envelopes; optional 2-bar chiptune loop on a 16-step scheduler.
- Entity caps in §3 are hard asserts in debug builds. No image assets, no fonts beyond system stack, no network calls — one `.html` file is the entire game.

*— End of GDD v1.0. All values are tuned per the §12 model; first playtest pass should re-verify the 2 s/3 s handling-time assumptions and the 1.3× blended revenue factor before touching any table.*
