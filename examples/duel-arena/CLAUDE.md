# CLAUDE.md — Duel Arena (working title)

Handover file for Claude Code. Read this fully before doing anything in this repo.
Last updated: 07/09/2026 by Darren (D).

> **Location note (added Session 1):** this project lives at `examples/duel-arena/` inside
> `darrenrollandi/agency-agents`, next to Ranch Rush. Every command in this file
> (`rojo`, `rokit`, `stylua`, `selene`) runs from that directory. See `docs/DECISIONS.md`
> for why and how to split it into its own repo later.

---

## 1. Who you're working with

- **Darren (D)** — owner and developer. Experienced dev (Python, TypeScript, SQL, Next.js/Supabase). **New to Luau and Roblox.** Explain Roblox-specific concepts once, briefly, when they first matter — don't explain general programming.
- **Mason** — D's son. **Tester.** He plays builds and gives feedback. He is not scripting or building in Studio for now. When D relays Mason's feedback, treat it as the primary playtest signal.

How D wants you to work:

- Concise and direct. No preamble, no recap of the question. Answer or act.
- Give **one recommendation**, not a menu. Flag judgment calls *after* making them.
- Code-first. Prose only where it adds something.
- Push back when D is wrong or when there's a simpler approach.
- Dates DD/MM/YYYY. Timezone SAST (UTC+2). English only.
- Ask before destructive actions (see §9 Guardrails).

---

## 2. The game

**Genre:** fast-paced first-person dueling game. Team sizes 1v1, 2v2, 3v3, 4v4.

**Core loop:**

1. Player lands in the **lobby**.
2. Player steps on a **duel pad** (one pad per team size). When the pad has enough players, they're teleported into a free **arena**.
3. A **duel** is a series of **rounds**. A round ends when one team is fully eliminated. Winning team gets a point. **First team to 5 wins the duel.**
4. Winners and losers return to the lobby. XP and unlock progress are awarded.

**Weapons:** every player gets the same two weapons in every duel:

- **Revolver** — hitscan, limited cylinder, reload.
- **Knife** — melee, fast, always available.

**Abilities:** each weapon has its own set of unique abilities that make the player stronger (cooldown-based). *The specific abilities are still to be designed with Mason — see §10 Open questions. Build the ability framework generically; don't hard-code a list until D confirms it.*

**Progression:** players unlock new **knife skins** and **revolver skins** as they progress. Skins are cosmetic only.

**Design principles (defaults — D to confirm):**

- Skill-based. No pay-to-win. Monetisation is cosmetic (skins, effects) plus optional convenience (XP boost).
- Rounds are short (target < 60 s). Getting back into the action fast matters more than anything.
- Readable over realistic. Stylised hits, no blood, bodies disappear/ragdoll briefly then despawn. This keeps the maturity label at **Mild** (accessible to Roblox Kids 5–8 and Select 9–15 audiences). Do not add realistic blood or gore — that pushes the label to Moderate/Restricted.
- Platform: PC/keyboard-mouse first. Design input handling through `ContextActionService` so touch and gamepad can be added later without rewrites.

---

## 3. Technical decisions (already made — don't relitigate without a reason)

| Area | Decision | Why |
|---|---|---|
| Source of truth for code | **Git repo + Rojo (≥ 7.7)**. All Luau lives as `.luau` files in `src/`. Rojo syncs them into Studio. | Real files, real diffs, real history. Studio's script editor has none of that. |
| Live Studio access | **Roblox Studio built-in MCP server** (Assistant → … → Manage MCP Servers). | Inspect the DataModel, run Luau, start/stop play, read console, screenshot, simulate input. |
| Rojo scope | **Partially managed.** Rojo owns `ReplicatedStorage/Shared`, `ServerScriptService/Server`, `StarterPlayer/StarterPlayerScripts/Client`. Everything else (Workspace maps, lighting, StarterGui layouts, Sounds) lives in the cloud place and is edited in Studio. | Maps and UI are visual; scripts are text. Keep each where it's easiest to edit. |
| Toolchain | **Rokit** manages `rojo`, `stylua`, `selene`, `luau-lsp`. Pin versions in `rokit.toml` via `rokit add <tool>` (pins latest at time of add). | Reproducible on D's machine and any future one. |
| Luau | `--!strict` on every file. Types for all public module APIs. | Catches the class of bug that otherwise only shows up in a live duel. |
| Architecture | **Server-authoritative.** Client predicts visuals only. All hits, damage, ammo, cooldowns, XP and unlocks are decided on the server. | Roblox exploiters are a certainty, not a risk. |
| Framework | **None.** Plain ModuleScripts: `Services/` on the server, `Controllers/` on the client, `Shared/` for both. One `Net` module wraps RemoteEvents/RemoteFunctions with payload validation. | Knit et al. add indirection D doesn't need to learn yet. |
| Player data | **ProfileStore** (MadStudioRoblox) — vendor the single `ProfileStore.luau` into `src/server/Vendor/`. No Wally. | Session locking and autosave solved; one file, no package manager to maintain. |
| Formatting / lint | StyLua (default config) + Selene (`roblox` std). Run both before every commit. | Non-negotiable hygiene. |
| Commits | Conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`). Small, focused. | D's standard across projects. |

**Why MCP *and* Rojo, not MCP alone:** MCP is for everything *live* (inspect, execute, playtest, screenshot). MCP's `multi_edit` writes script Source straight into the place with no history or diff; for a proper-release project that's a footgun, so Rojo + git own the scripts. If D ever decides to go Studio-only, remove the Rojo rows above and switch to `multi_edit`/`script_read` — accepting the loss of version control.

---

## 4. Repo layout

```
duel-arena/
├── CLAUDE.md                  ← this file
├── README.md                  ← one-paragraph human intro + setup commands
├── rokit.toml                 ← toolchain pins
├── default.project.json       ← Rojo project (partially managed)
├── .luaurc                    ← Luau strict + aliases
├── selene.toml
├── stylua.toml
├── .gitignore
├── docs/
│   ├── STATUS.md              ← what's done, what's next, known bugs — UPDATE EVERY SESSION
│   ├── DECISIONS.md           ← ADR-style log: date, decision, why, alternatives rejected
│   ├── GAME_DESIGN.md         ← living design doc (abilities, skins, XP curve, maps)
│   └── ROBLOX_PRIMER.md       ← Roblox concepts for D, written as they come up
├── tests/                     → ServerStorage.Tests (pure-logic tests, see §8)
│   └── RunTests.luau
└── src/
    ├── shared/                → ReplicatedStorage.Shared
    │   ├── Config/            ← tunables: weapon stats, round rules, XP curve (one module each)
    │   ├── Net/               ← remote definitions + payload validators
    │   ├── Types.luau         ← shared type definitions
    │   └── Util/
    ├── server/                → ServerScriptService.Server
    │   ├── init.server.luau   ← bootstraps all Services in order
    │   ├── Services/
    │   │   ├── MatchmakingService.luau   ← pads, queues, arena allocation
    │   │   ├── DuelService.luau          ← round/duel state machine
    │   │   ├── CombatService.luau        ← hit validation, damage, deaths
    │   │   ├── AbilityService.luau       ← cooldowns, ability execution (server side)
    │   │   ├── DataService.luau          ← ProfileStore wrapper
    │   │   ├── ProgressionService.luau   ← XP, levels, unlocks
    │   │   ├── MonetisationService.luau  ← game passes, dev products, ProcessReceipt
    │   │   └── AnalyticsService.luau     ← wraps Roblox AnalyticsService
    │   └── Vendor/
    │       └── ProfileStore.luau
    └── client/                → StarterPlayer.StarterPlayerScripts.Client
        ├── init.client.luau   ← bootstraps all Controllers
        └── Controllers/
            ├── CameraController.luau     ← first-person lock, recoil, FOV
            ├── WeaponController.luau     ← input, viewmodel, local prediction, fire requests
            ├── AbilityController.luau
            ├── HudController.luau        ← health, ammo, round score, timers
            ├── LobbyController.luau      ← pad prompts, queue status
            └── LockerController.luau     ← skins UI
```

Rojo naming: `*.server.luau` → Script, `*.client.luau` → LocalScript, `*.luau` → ModuleScript, `init.*.luau` makes the folder itself the instance.

---

## 5. Session workflow

Every session, in this order:

1. `git pull` (if D worked from another machine). Read `docs/STATUS.md`.
2. Confirm toolchain: `rokit install` then `rojo --version`.
3. `rojo serve` in a background terminal. D opens the place in Studio and clicks **Connect** in the Rojo plugin.
4. Confirm MCP: call `list_roblox_studios`. Use the returned `studio_id` on every subsequent MCP call. If Studio isn't listed, tell D — don't retry in a loop.
5. Work in small increments: edit `.luau` files → Rojo syncs on save → `start_stop_play` → `get_console_output` → `screen_capture` if visual → fix → repeat.
6. Before committing: `stylua src/` and `selene src/`. Fix everything Selene reports.
7. End of session: update `docs/STATUS.md` (done / next / bugs), commit, tell D in three lines what changed and what he should playtest with Mason.

**Multi-player testing** (anything involving an actual duel): the MCP `start_stop_play` runs a single client. For 2+ players use Studio's **Test → Clients and Servers** with 2–8 players. Ask D to run this and report, or prepare a scripted scenario via `execute_luau` on the Server DataModel that spawns test dummies into an arena so you can exercise the round state machine solo.

**MCP rules:**

- `execute_luau` with `datamodel_type = "Edit"` **changes the saved place**. Use it for read-only inspection or building lobby/arena scaffolding D asked for. Never to write script Source — that's Rojo's job and Rojo will overwrite it.
- `script_read`, `script_search`, `script_grep`, `search_game_tree`, `inspect_instance` — use freely.
- `multi_edit` — **do not use** while Rojo is serving (see §3).
- `insert_asset` / `search_asset` — only for meshes, textures, audio. **Never insert a Creator Store model that contains scripts** without reading every script first (free-model backdoors are common). Prefer `generate_procedural_model` for placeholder geometry.
- `user_keyboard_input`, `user_mouse_input`, `character_navigation` — use for automated playtests of movement, firing and UI flows.

---

## 6. Architecture rules

**Networking (`src/shared/Net/`):**

- One `Net.luau` module creates and caches all RemoteEvents/RemoteFunctions under `ReplicatedStorage.Shared.Net.Remotes` at server start. Clients wait for them.
- Every remote has a validator function on the server. Invalid payload → drop silently, increment a per-player strike counter, log once.
- Rate-limit every client→server remote per player (e.g. fire requests capped at weapon `FireRate × 1.25`).
- Prefer `RemoteEvent` for fire-and-forget; `RemoteFunction` only client→server and only where a return value is required. Never server→client `RemoteFunction`.
- Use `UnreliableRemoteEvent` for high-frequency cosmetic updates (tracers, footsteps) — never for anything that affects state.

**Combat model:**

- Client raycasts locally for instant feedback (muzzle flash, tracer, hit marker), then sends `{origin, direction, hitInstance?, timestamp}`.
- Server validates: player is alive and in a duel; ammo > 0; fire rate honoured; `origin` within ~8 studs of the player's head; then **re-raycasts on the server** from `origin` along `direction`. Server result is truth. Accept a client hit only if the server ray hits the same character or passes within a small tolerance of it (basic lag tolerance, no full rollback — keep it simple first; revisit if Mason reports "I clearly hit him").
- Knife: server-side hitbox check (`WorldRoot:GetPartBoundsInBox`) on the swing tick, facing-direction gated.
- Damage numbers, health, deaths — server only. Client reads via replicated attributes on the character.

**State:**

- `DuelService` is a strict state machine: `Waiting → Countdown → Live → RoundOver → (Countdown | DuelOver) → Cleanup`. Every transition is logged. No gameplay code outside `Live`.
- Arenas are instanced from a template in `ServerStorage.ArenaTemplates`, cloned per duel, destroyed after. Never share an arena between duels.
- Player state (which duel, which team, alive/dead, loadout) lives in a server-side table keyed by `Player`, never on the client and never solely in attributes.

**Data (`DataService`):**

- Profile template in `src/shared/Config/ProfileTemplate.luau`. Add fields there only — never write ad-hoc keys.
- `Profile.Data` is only touched through `ProgressionService`/`MonetisationService` functions. No direct writes from elsewhere.
- Handle `StartSessionAsync` failure by kicking the player with a friendly message — never let someone play with unsaved data.
- Keep **Game Settings → Security → "Enable Studio Access to API Services" off** (the default) so Studio sessions can't touch live DataStores. Gate data code behind a `Config.UseMockData` flag that's true in Studio, so P1–P3 never depend on DataStores at all.

**Client:**

- First-person lock via `StarterPlayer.CameraMode = LockFirstPerson`. Viewmodel (arms + weapon) is a client-only rig parented to `Camera`, updated on `RenderStepped`.
- Input through `ContextActionService` with named actions (`Fire`, `Reload`, `SwapWeapon`, `Ability1`, `Ability2`). No raw `UserInputService.InputBegan` in gameplay code.
- UI layouts are built in Studio under `StarterGui` (D or you via `execute_luau`). Controllers find them by name and wire behaviour. Never build layouts programmatically unless it's dynamic (e.g. a list of skins).

**General Luau:**

- `task.wait()`, `task.spawn()`, `task.defer()` — never legacy `wait()`/`spawn()`/`delay()`.
- No `while true do task.wait() end` polling where an event exists.
- `:Connect` returns must be stored and `:Disconnect`ed on cleanup (round end, character death, player leave). Use a small `Trove`/`Janitor`-style cleanup helper in `src/shared/Util/`.
- Tunables (damage, fire rate, round time, XP per win) live in `src/shared/Config/`, never as literals in Services.

---

## 7. Roadmap — "done when" gates

Work through these in order. Don't start a phase until the previous one's gate passes with Mason.

| Phase | Scope | Done when |
|---|---|---|
| **P0 Bootstrap** | Repo, toolchain, Rojo project, MCP connection, empty lobby with one pad, `docs/` skeleton | Rojo syncs a `print("hello")` into Studio; MCP `list_roblox_studios` returns the place; first commit pushed. |
| **P1 Core loop** | Pads → queue → arena teleport; `DuelService` state machine; kill = team point; first to 5; return to lobby. Placeholder "tag" damage (touch = kill) so no weapons needed yet | Two clients in Test mode can complete a full 1v1 duel to 5 and land back in the lobby. No errors in console. |
| **P2 Weapons** | Revolver (hitscan, cylinder, reload) and knife (melee) with server validation; viewmodel; hit markers; death handling | Mason plays a 1v1 vs D and says it "feels good". No hit-reg complaints in 10 rounds. Exploit test: a client script that spoofs a hit does nothing. |
| **P3 Abilities** | Generic ability framework (cooldowns, server execution, client VFX); first 2 abilities per weapon per `GAME_DESIGN.md` | All abilities work in a 2v2. Cooldowns enforced server-side. |
| **P4 Progression + data** | ProfileStore; XP per duel; levels; skin unlocks; locker UI | Leave and rejoin keeps XP, level, equipped skins. Session-lock tested with two Studio instances. |
| **P5 UI/UX** | HUD (health, ammo, round score, timers), pad prompts, results screen, settings (sensitivity, FOV) | Mason can navigate everything without asking D. |
| **P6 Monetisation** | Skin game passes; a dev product (e.g. XP boost); `ProcessReceipt` idempotent via `PurchaseHistory` in profile | Test purchases in Studio work; a replayed receipt is not granted twice; purchase state survives rejoin. |
| **P7 Analytics + release prep** | `AnalyticsService` funnels (join → pad → first duel → first win), economy events, progression events; maturity questionnaire answers drafted; place settings checklist | D can see funnel data in Creator Hub after a test session. Questionnaire drafted in `docs/RELEASE_CHECKLIST.md`. |
| **P8 Polish** | Sound, VFX, 2–3 arena maps, performance pass (60 fps on D's machine, memory budget), bug bash with Mason's friends | Release checklist complete. D publishes (not you). |

Each phase ends with a `docs/STATUS.md` update and a tagged commit (`v0.1.0` for P1, `v0.2.0` for P2, …).

---

## 8. Code standards

- Filenames `PascalCase.luau` for modules; `init.server.luau`/`init.client.luau` for entry points.
- Every module returns a table with an explicit type; public functions documented with a one-line comment. No comment noise on obvious code.
- Errors: `error()` for programmer mistakes, `warn()` + graceful degradation for runtime/network issues. Never swallow errors silently.
- Logging: a `Log` util with levels; `Log.debug` no-ops unless `Config.Debug = true`.
- Tests: pure logic (XP curves, state transitions, validators) gets tests runnable via `execute_luau` on the Edit DataModel — a `tests/` folder mounted into `ServerStorage.Tests` and a `RunTests.luau` entry. Don't test Roblox engine behaviour.
- No third-party packages beyond ProfileStore without asking D. If you need one, propose it in `docs/DECISIONS.md` first.

---

## 9. Guardrails — always ask D first

- Publishing the place, changing place/universe settings, or anything on the Creator Dashboard. **You never publish.**
- Creating or editing game passes / developer products on the dashboard (you write the code; D creates the products and gives you the IDs for `Config/Monetisation.luau`).
- Anything that costs Robux.
- Deleting or overwriting DataStore keys, or enabling Studio access to live DataStores.
- `execute_luau` in Edit mode that deletes or bulk-modifies Workspace/StarterGui contents.
- Inserting any Creator Store asset that contains scripts.
- Adding a dependency, framework, or changing a §3 decision.
- Force-pushing, rewriting history, or deleting branches.

Use dummy/sample data for anything player-facing in tests. Never real player IDs.

---

## 10. Open questions for D (ask at the start of the first session, then move them into `docs/GAME_DESIGN.md`)

1. Working title — "Duel Arena" is a placeholder.
2. Team sizes: are all four (1v1, 2v2, 3v3, 4v4) needed at launch, or ship 1v1 + 2v2 first?
3. Round end: team fully eliminated (assumed). Round timer if nobody dies? Sudden-death rule?
4. Abilities: how many per weapon (assume 2–3), and are they chosen before a duel (loadout) or fixed for everyone? This is a good design session to run with Mason.
5. Progression currency: XP-only levels, or XP + a soft currency for buying skins?
6. Revolver numbers: cylinder size (6?), damage per shot, headshot multiplier, reload time. Knife: one-hit or two-hit kill?
7. Friendly fire in team modes? (Assume off.)
8. Art direction: low-poly stylised vs blocky Roblox-default vs something else. Affects every asset decision.
9. Platforms at launch: PC only, or PC + mobile + console?
10. Does Mason want an in-game credit ("Lead Tester")?

---

## 11. Session 1 — bootstrap instructions

Run these in order. Stop and report if any step fails.

1. **Toolchain**
   - Install Rokit if missing: Windows `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`; macOS `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`.
   - `rokit init` then `rokit add rojo-rbx/rojo`, `rokit add JohnnyMorganz/StyLua`, `rokit add Kampfkarren/selene`, `rokit add JohnnyMorganz/luau-lsp`. Confirm `rojo --version` is ≥ 7.7.
   - `rojo plugin install` to put the Rojo plugin into Studio.
2. **Repo skeleton** — create the tree in §4 with empty-but-valid modules (each returns `{}` under `--!strict`), plus the config files in §12. `git init`, first commit `chore: bootstrap duel-arena`.
3. **Studio side (D does this, you guide):** create a new place in Studio, save it to Roblox (private), enable the built-in MCP server (Assistant → … → Manage MCP Servers → Enable Studio as MCP server → Quick connect → Claude Code). Restart Claude Code if the server doesn't appear.
4. **Connect:** `rojo serve`; D clicks Connect in the Rojo plugin. Call `list_roblox_studios`; record the `studio_id`. Run `execute_luau` (Edit) with `print(game.PlaceId)` to prove the loop works.
5. **Hello world:** `src/server/init.server.luau` prints `"[Server] Duel Arena booted"`. `start_stop_play`, then `get_console_output` and confirm the line appears. Stop play.
6. **Lobby scaffold:** via `execute_luau` (Edit), build a flat lobby baseplate, a spawn location, and one `Part` named `Pad_1v1` with a `ProximityPrompt`/`Touched` placeholder. Set `StarterPlayer.CameraMode = LockFirstPerson`. Screenshot it for D.
7. **Docs:** write `docs/STATUS.md` (P0 complete, P1 next, open questions from §10 listed), `docs/DECISIONS.md` (seeded from §3), `docs/GAME_DESIGN.md` (seeded from §2), `docs/ROBLOX_PRIMER.md` (Script vs LocalScript vs ModuleScript; where things live; client/server boundary — five short paragraphs max).
8. Commit, tag `v0.0.1`, report to D in three lines.

---

## 12. Config files (create verbatim in Session 1, then adjust)

**`default.project.json`**

```json
{
  "name": "duel-arena",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "ServerStorage": {
      "Tests": { "$path": "tests" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

**`.luaurc`**

```json
{
  "languageMode": "strict",
  "lint": { "*": true },
  "aliases": {
    "Shared": "src/shared",
    "Server": "src/server",
    "Client": "src/client"
  }
}
```

**`selene.toml`**

```toml
std = "roblox"

[lints]
shadowing = "allow"
```

Current Selene generates the `roblox` std automatically; if it complains the std is missing, run `selene generate-roblox-std` once.

**`stylua.toml`**

```toml
column_width = 100
indent_type = "Tabs"
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

(Tabs are the Roblox/StyLua convention. D uses 4-space indents elsewhere; Studio renders tabs as 4 spaces, so this matches visually.)

**`.gitignore`**

```
*.rbxl
*.rbxlx
*.rbxl.lock
*.rbxlx.lock
sourcemap.json
/build/
.DS_Store
```

**`rokit.toml`** — generated by `rokit add`; commit it as generated.

---

## 13. Roblox quick reference for D (expand in `docs/ROBLOX_PRIMER.md`)

| Roblox thing | Closest analogy for D |
|---|---|
| `Script` (server) | Backend service — trusted, has DB access |
| `LocalScript` (client) | Browser JS — untrusted, per player |
| `ModuleScript` | An importable module (`require`) — runs wherever it's required |
| `ReplicatedStorage` | Shared code/assets visible to both — like a `shared/` package |
| `ServerScriptService` / `ServerStorage` | Server-only code and assets — clients literally can't see them |
| `StarterPlayerScripts` | Client scripts copied to each player on join |
| `RemoteEvent` / `RemoteFunction` | WebSocket message / RPC across the trust boundary |
| `DataStoreService` | Key-value DB with rate limits; ProfileStore is the ORM |
| Rojo | The build tool that turns files into instances — think `next dev` |
| Studio "Play" vs "Clients and Servers" | Single-process dev server vs a real multi-client test |
| Maturity questionnaire | App-store age rating, self-declared, enforced at publish |

---

## 14. Useful references (fetch via MCP `http_get` or WebFetch when needed)

- Studio MCP server docs: https://create.roblox.com/docs/studio/mcp
- Rojo docs: https://rojo.space/docs/v7/
- Rokit: https://github.com/rojo-rbx/rokit
- ProfileStore: https://github.com/MadStudioRoblox/ProfileStore
- Content maturity / questionnaire: https://create.roblox.com/docs/production/promotion/content-maturity
- Engine API reference: https://create.roblox.com/docs/reference/engine
- `MarketplaceService.ProcessReceipt`: https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt
- `AnalyticsService`: https://create.roblox.com/docs/reference/engine/classes/AnalyticsService
