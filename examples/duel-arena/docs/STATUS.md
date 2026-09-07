# Status

Updated 07/09/2026 (Session 2, first live Studio session).

## Phase: P0 Bootstrap — COMPLETE (07/09/2026)

Gate check (CLAUDE.md §7): Rojo syncs into Studio ✔, MCP `list_roblox_studios` returns the place ✔, first commit pushed ✔.

- [x] Repo skeleton at `examples/duel-arena/` per CLAUDE.md §4. Every module is `--!strict` and returns a typed table.
- [x] Config files from §12: `default.project.json`, `.luaurc`, `selene.toml`, `stylua.toml`, `.gitignore`.
- [x] `rokit.toml` pins rojo 7.7.0, StyLua 2.5.2, Selene 0.31.0, luau-lsp 1.69.0. `rojo --version` confirmed 7.7.0 on D's machine.
- [x] Studio place **Duel Arena Dev** (placeId `122469071823351`) saved privately; built-in MCP server enabled and reachable from Claude Code.
- [x] Rojo connected: `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `ServerStorage.Tests`, `StarterPlayerScripts.Client` all present in the DataModel.
- [x] MCP round-trip verified: `execute_luau` (Edit) returned `game.PlaceId = 122469071823351`.
- [x] Play run: console shows `[Server] Duel Arena booted` and `[Client] Duel Arena client booted`.
- [x] Tests: `require(ServerStorage.Tests.RunTests)()` → `3 passed, 0 failed`.
- [x] Lobby scaffold built via `execute_luau` (Edit), saved in the cloud place (not Rojo-managed):
  - `Workspace.LobbyFloor` — the default Baseplate renamed and shrunk to 128×4×128, top surface at y = 0.
  - `Workspace.Lobby` (Folder) containing `SpawnLocation` (12×1×12 at z = +30, facing the pad) and `Pad_1v1` (10×1×10 neon part at z = −20, attribute `TeamSize = 1`, `ProximityPrompt` "Queue 1v1" on E, BillboardGui label "1v1").
  - `StarterPlayer.CameraMode = LockFirstPerson`.
- [x] Docs seeded: DECISIONS, GAME_DESIGN, ROBLOX_PRIMER.

## Next: P1 Core loop

Pads → queue → arena teleport; `DuelService` state machine; touch = kill placeholder damage; first to 5; back to lobby. Gate: two clients in Test mode complete a full 1v1 with no console errors.

Suggested order:

1. `MatchmakingService`: read `Pad_*` parts from `Workspace.Lobby`, `TeamSize` attribute → queue; `ProximityPrompt.Triggered` (or `Touched`) enqueues/dequeues.
2. Arena template in `ServerStorage.ArenaTemplates` (built via `execute_luau`), cloned per duel.
3. `DuelService` state machine with logged transitions; `tests/DuelState.spec.luau`.
4. Touch-to-kill placeholder in `CombatService`; scoring; return to lobby.

Before starting P1, answer the open questions below (a 15-minute session with Mason covers most of them).

## Open questions for D (from CLAUDE.md §10)

1. Working title.
2. Ship all four team sizes at launch, or 1v1 + 2v2 first?
3. Round timer when nobody dies? Sudden-death rule?
4. Abilities per weapon (2–3?), loadout-picked or fixed?
5. XP-only levels, or XP + soft currency for skins?
6. Revolver: cylinder size, damage, headshot multiplier, reload time. Knife: one- or two-hit kill?
7. Friendly fire in team modes (assume off)?
8. Art direction.
9. Launch platforms.
10. In-game "Lead Tester" credit for Mason?

## Known bugs

None.

## Notes

- Tag `v0.0.1` on the P0 commit once it's on `main`.
- The lobby scaffold lives only in the cloud place. D must **save/publish the place from Studio** after this session or the scaffold is lost (Rojo does not manage Workspace).
- `execute_luau` prints go to Studio's Output window, not the tool result — `return` a string to read values back.
- `src/server/Vendor/ProfileStore.luau` is not vendored yet; not needed before P4.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` if it complains the std is missing.
