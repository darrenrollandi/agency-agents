# Decisions

ADR-style log. Newest at the bottom. Format: date, decision, why, alternatives rejected.

## 07/09/2026 — Code lives in git and syncs to Studio with Rojo (≥ 7.7)

All Luau is `.luau` files under `src/`. Rojo syncs them into the place. Real diffs, history and review. Rejected: Studio-only scripting (no version control); MCP `multi_edit` as the write path (writes Source straight into the place, no history).

## 07/09/2026 — Roblox Studio built-in MCP server for everything live

Inspect the DataModel, run Luau, start/stop play, read console, screenshot, simulate input. Complements Rojo; never replaces it for script source.

## 07/09/2026 — Rojo is partially managed

Rojo owns `ReplicatedStorage/Shared`, `ServerScriptService/Server`, `ServerStorage/Tests`, `StarterPlayer/StarterPlayerScripts/Client`. Maps, lighting, StarterGui layouts and sounds live in the cloud place and are edited in Studio. Rejected: fully managed place (visual assets are painful as files); fully Studio (no history for scripts).

## 07/09/2026 — Rokit manages the toolchain

`rojo`, `stylua`, `selene`, `luau-lsp` pinned in `rokit.toml`. Reproducible on any machine. Rejected: Aftman (superseded by Rokit); Foreman (older, less maintained); global installs.

## 07/09/2026 — `--!strict` everywhere, typed public module APIs

Catches the bugs that otherwise only appear in a live duel. Rejected: nonstrict for speed.

## 07/09/2026 — Server-authoritative gameplay

Hits, damage, ammo, cooldowns, XP and unlocks are decided on the server. Client predicts visuals only. Roblox exploiters are a certainty. Rejected: client-authoritative hits with server sanity checks (trivially spoofable).

## 07/09/2026 — No framework

Plain ModuleScripts: `Services/` (server), `Controllers/` (client), `Shared/`. One `Net` module wraps remotes with validation. Rejected: Knit and similar (indirection D doesn't need to learn yet).

## 07/09/2026 — ProfileStore for player data, vendored, no Wally

Session locking and autosave solved by one vendored `ProfileStore.luau`. Rejected: raw DataStoreService (session-lock bugs are a rite of passage nobody needs); Wally (a package manager for one dependency).

## 07/09/2026 — StyLua (default) + Selene (`roblox` std) before every commit

Non-negotiable hygiene. Tabs, 100 columns, double quotes, always parentheses.

## 07/09/2026 — Conventional commits

`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`. Small and focused.

## 07/09/2026 — Project lives at `examples/duel-arena/` in `darrenrollandi/agency-agents`

The bootstrap session had no dedicated repo available and only the eight scoped repos. `agency-agents/examples/` already hosts Ranch Rush, D's previous game project, so the same home was used. All Rojo, Rokit and lint commands run from `examples/duel-arena/`. Rejected: creating a new repo (outside the session's authority). Revisit: a dedicated `duel-arena` repo is cleaner for Rojo and tags; `git subtree split -P examples/duel-arena` moves it with history intact.

## 07/09/2026 — Toolchain pinned from crates.io, not `rokit add`

The bootstrap environment could reach crates.io but not GitHub releases, so `rokit.toml` was written by hand with the latest published versions (rojo 7.7.0, StyLua 2.5.2, Selene 0.31.0). luau-lsp is not on crates.io and is left for D to `rokit add`. Rokit reads the file the same way either way.

## 07/09/2026 — LF line endings enforced via `.gitattributes`

D's machine has `core.autocrlf=true`, which checked `.luau` out as CRLF and made StyLua report every line of every file as a diff. The project `.gitattributes` forces LF for `.luau`, `.json`, `.toml`, `.md`, `.luaurc`. Rejected: StyLua `line_endings = "Windows"` (breaks on any non-Windows machine); turning autocrlf off globally (D's other repos may rely on it).

## 07/09/2026 — Duel pads are step-on zones, not ProximityPrompts

Standing on a pad queues you; stepping off leaves. Occupancy is one `GetPartBoundsInBox` per pad every 0.2 s. Why: ProximityPrompts only render when their part is on screen, and in locked first person the pad you're standing on is under your feet, so the prompt never appears; the design doc also says "player steps on a duel pad". Rejected: prompt on a sign next to the pad (extra UI, still needs the player to look at it); `Touched`/`TouchEnded` (TouchEnded is unreliable for "still standing here").

## 07/09/2026 — P1 placeholder combat is a server-side "Tag" Tool, not touch-to-kill

CLAUDE.md suggested touch = kill. Touch is symmetric: both characters touch each other, so both die and every round is a draw. Instead each duelist gets a Tool when a round goes Live; `Tool.Activated` fires on the server, which runs a directional box hitbox in front of the attacker and applies `TakeDamage`. Zero client code, zero remotes, and it is the skeleton of the P2 knife. Rejected: touch-kill; a click remote (would need Net validation before Net had any C→S traffic).

## 07/09/2026 — `Players.CharacterAutoLoads = false`; CharacterService owns spawning

Default auto-respawn would drop a dead duelist back at the lobby SpawnLocation mid-round. CharacterService loads characters explicitly: lobby respawn after 3 s, duel respawn only when DuelService starts the next round (`LoadCharacter` + `PivotTo` onto the team spawn). Rejected: `Player.RespawnLocation` swapping (its interaction with disabled SpawnLocations is murky); keeping auto-load and teleporting on `CharacterAdded` (a visible frame at the lobby spawn every round).

## 07/09/2026 — Arena template is generated by `ArenaBuilder.luau`, with a runtime fallback

The canonical `ServerStorage.ArenaTemplates.Arena_Basic` is created once via `execute_luau` from `ArenaBuilder.build()` and can be edited visually in Studio afterwards. If the template is missing at runtime (place not saved), `Arena.luau` rebuilds it from the same code with a warning, so a forgotten save never blocks a playtest. Same pattern for `StarterGui.DuelHud` via `Shared/Util/HudLayout`. Rejected: hand-building in Studio only (lost if unsaved, no reproducibility); code-only arenas (D can't tune them visually).

## 07/09/2026 — Round defaults chosen to unblock P1 (D to confirm)

1v1 ships first (code supports all four sizes via the pad `TeamSize` attribute). 90 s round timer; on expiry the team with more survivors wins, a tie becomes sudden death with no timer. Simultaneous wipe is a draw and the round is replayed. Friendly fire off. All in `Shared/Config/Rounds.luau`. These are defaults, not design decisions: change them after Mason's first playtest.

## 07/09/2026 — Timers are synced by timestamp, not by ticking

Server sends `countdownEndsAt` / `roundEndsAt` as `workspace:GetServerTimeNow()` seconds once per state change; the client computes the remaining time locally. Rejected: a per-second server broadcast (network noise, drifts under latency).

## 07/09/2026 — Studio-only `DebugCommands` BindableFunction for solo testing

`require` from the command bar or MCP `execute_luau` gets its own module instance, so it cannot see the running services' state. `ServerStorage.DebugCommands` (created only when `Config.Debug`) exposes `startDuel`, `abort`, `kill`, `state`, `activeDuels` on the live instances. Never exists in a published server. Rejected: a debug RemoteFunction (attack surface); `_G` (untyped, easy to leak).

## 07/09/2026 — Weapons are not Tools

The revolver and knife are a fixed loadout, so the Roblox Tool/Backpack system (equip slots, drop, the default hotbar UI) only gets in the way. Loadout state (weapon, ammo, reloading, fire timestamps) lives in CombatService and is published to the owning client as Player attributes `Weapon`, `Ammo`, `Reloading`. Input goes through ContextActionService as CLAUDE.md requires. Rejected: Tools (P1's Tag placeholder proved they work but drag the hotbar and equip semantics with them).

## 07/09/2026 — Server re-raycast with a fixed lag-tolerance corridor

The client sends `{origin, direction, hitPart?, timestamp}`. The server drops the shot if the origin is more than 8 studs from the shooter's head, if the fire interval, ammo or reload state disagree, then raycasts itself. Its ray decides headshots. If its ray misses but the claimed victim's root lies within 3 studs of the ray with nothing solid in between, it counts as a body hit. No rollback, no history buffer. Rejected: trusting the client's hitPart (trivially spoofable, and the smoke test shows it being ignored); full lag compensation (complexity not justified until Mason reports missed hits).

## 07/09/2026 — Non-player humanoids are always hittable

CombatService damages any model with a Humanoid; the friendly-fire and same-duel checks apply only when the model belongs to a Player. This makes training dummies (`DebugCommands.dummy`) work for solo hit-reg tests and leaves room for lobby target practice. Rejected: player-only damage (would have made P2 untestable without a second machine).

## 07/09/2026 — Weapon geometry is code (`Shared/WeaponModels`), shared by viewmodel and world model

One builder produces the blocky revolver/knife for the client viewmodel (anchored, pivoted every frame under the Camera) and the server's hand-welded third-person model. Parts never collide or answer raycasts (`CanQuery = false`), so a weapon can't shield its owner. Skins (P4) replace the builder output per weapon. Rejected: mesh assets now (art direction is still an open question).

## 07/09/2026 — Weapon defaults chosen to unblock P2 (D and Mason to tune)

Revolver: 6 rounds, 35 body, ×2 head (70), 0.4 s between shots, 1.6 s reload, 400-stud range. Knife: 50 damage (two-hit kill), 6-stud box, 0.45 s between swings. Health 100, so three body shots or head + body. All in `Shared/Config/Weapons.luau`; recoil and FOV in `Config/Camera.luau`.

## 07/09/2026 — Edit-mode `require` is cached: setup snippets require clones

In the Edit DataModel, `require(ModuleScript)` from the command bar or MCP is cached across runs, so a setup snippet that rebuilt the HUD after a code change produced the old layout. Requiring a *clone* of the module forces a fresh load of the current Source. Every setup snippet in STATUS.md now does this. Rejected: restarting Studio to clear the cache.

## 07/09/2026 — Abilities: fixed loadout of two per weapon, data-driven, server-executed

`Shared/Config/Abilities.luau` is the only place an ability is defined (id, weapon, slot, cooldown, params). `AbilityService` owns cooldowns (reset every round, published as `Cooldown_<Id>` attributes holding a server timestamp) and runs every effect that touches state through CombatService or the Humanoid. The client sends only `UseAbility(slot)`; `AbilityUsed` fans out for VFX. Dash is the one exception: the owning client applies a short LinearVelocity burst because it owns its character's physics anyway; the server still gates the cooldown. Defaults: Speed Loader (instant reload, 12 s), Dead Eye (next shot ×2 within 4 s, 15 s), Dash (70 studs/s for 0.18 s, 6 s), Second Wind (+40 HP over 2 s, 18 s). Rejected: per-player loadout picking (an open design question; the data model supports it later by mapping slots per player instead of per weapon); client-computed cooldowns (spoofable).

## 07/09/2026 — Player data: ProfileStore vendored, Mock in Studio, kick on load failure

`src/server/Vendor/ProfileStore.luau` is the upstream file (MadStudioRoblox/ProfileStore main, 07/09/2026), excluded from StyLua and Selene. `DataService` opens one session-locked profile per player and uses `store.Mock` whenever `Config.UseMockData` (true in Studio), so Studio never touches live DataStores even if API access were enabled. A failed load kicks with a friendly message; a stolen session kicks too. `Profile.Data` is written only by ProgressionService (and MonetisationService in P6). Expected Studio console noise: ProfileStore probes DataStore access once at load and prints "Roblox API services unavailable - data will not be saved"; that is the Mock working as intended. Rejected: raw DataStoreService (session-lock bugs); loading in the background and letting the player duel unsaved.

## 07/09/2026 — Progression is XP-only, level curve 50·L·(L+1), skins unlock by level or game pass

No soft currency until D asks for one: XP → level → skins keeps the loop legible for the target audience. Rewards: 100 XP a win, 40 a loss, 10 per round won, ×2 under an XP boost (P6). Curve in `Shared/Config/XP.luau`; skins in `Shared/Config/Skins.luau` (palette + `unlockLevel` or `gamePassId`). Skin ids are stored in profiles and must never be renamed. Progression state is published as Player attributes (XP, Level, EquippedRevolver, EquippedKnife) plus a `ProgressionSnapshot` remote for the locker; the server's world model and the client's viewmodel both read the equipped skin from attributes, which avoids a CombatService ↔ ProgressionService require cycle. Nobody can queue for a duel until their profile is loaded. Rejected: XP + coins (a second economy to balance before the first is proven).

## 07/09/2026 — Locker UI is built in code

The locker is a dynamic list (skins × ownership × level), the one case CLAUDE.md allows programmatic layout for. It lives in `LockerController`, toggles with L / gamepad Select in the lobby only, and frees the mouse while open by forcing `MouseBehavior = Default` after the camera step each frame (first person re-locks it otherwise). Rejected: a StarterGui layout with placeholder rows (would need code to clone rows anyway).

## 07/09/2026 — HUD panels are static layouts in StarterGui, found by unique name

Results, settings and the lobby hint block are fixed layouts, so per CLAUDE.md they live in `StarterGui.DuelHud`, generated once by `Shared/Util/HudLayout` (the setup snippet) and editable in Studio. Controllers locate elements with a recursive `FindFirstChild(name, true)`, so every element name in the HUD is unique and renaming one in Studio means renaming it in code. If the place's HUD predates an element the client rebuilds the whole HUD from code with a warning rather than failing. Panels expose an `Open` attribute so other UI and tests can toggle them without keyboard input.

## 07/09/2026 — Settings are two numbers, saved to the profile, adjustable by keyboard or mouse

Sensitivity (0.2–3.0, applied to `UserInputService.MouseDeltaSensitivity`) and FOV (60–100). Validated for range by the Net definition, persisted by ProgressionService (the only Profile.Data writer) after a 0.6 s debounce, loaded from the ProgressionSnapshot on join. Every panel that needs the cursor uses `client/MouseFree`, a ref-counted helper that forces `MouseBehavior = Default` after the camera step; arrow keys work as well because first-person mouse release can't be verified from MCP. Rejected: Roblox's built-in sensitivity slider only (no FOV, no persistence per game).

## 07/09/2026 — Server broadcasts DuelOver before awarding XP

Clients reliable-order events from one server thread, so `DuelService` broadcasts the DuelOver update first and calls `ProgressionService.recordDuel` second. The results panel is therefore already open when `DuelReward` lands and can fill its XP and unlock lines. Found because the smoke test showed an empty XP line.

## 07/09/2026 — Monetisation: ids in one config, idempotent receipts via the profile, server-side prompts

`Shared/Config/Monetisation.luau` holds every game-pass and developer-product id; D creates them on the dashboard (CLAUDE.md §9) and pastes the numbers. An id of 0 keeps the feature inert everywhere (no BUY row, prompts refused). `MonetisationService` owns `MarketplaceService.ProcessReceipt`: a receipt whose `PurchaseId` is already in `Profile.Data.PurchaseHistory` (capped at 50, oldest evicted) is acknowledged without granting again; an unknown product or an unloaded profile returns `NotProcessedYet` so Roblox retries later. Game-pass skins are granted on join via `UserOwnsGamePassAsync` and on `PromptGamePassPurchaseFinished`. The client never sees an id: it sends `RequestPurchase(kind, key)` and the server prompts. In Studio a fake product id (`999999001`) is registered only when `Config.Debug`, so the DebugCommands `receipt` harness can prove idempotency without Robux. Rejected: client-side `PromptProductPurchase` with ids in ReplicatedStorage (ids leak, harder to swap); a DataStore of receipts separate from the profile (two sources of truth to keep in sync).
