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
