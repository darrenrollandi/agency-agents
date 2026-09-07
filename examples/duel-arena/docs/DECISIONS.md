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
