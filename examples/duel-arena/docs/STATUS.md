# Status

Updated 07/09/2026 (Session 1, remote bootstrap).

## Phase: P0 Bootstrap — partially complete

Done in this session (no Studio available, so everything file-side):

- [x] Repo skeleton at `examples/duel-arena/` per CLAUDE.md §4. Every module is `--!strict` and returns a typed table.
- [x] Config files from §12: `default.project.json`, `.luaurc`, `selene.toml`, `stylua.toml`, `.gitignore`.
- [x] `rokit.toml` pinned to rojo 7.7.0, StyLua 2.5.2, Selene 0.31.0 (from crates.io; GitHub was blocked in the bootstrap environment). luau-lsp not pinned yet.
- [x] `src/server/init.server.luau` prints `[Server] Duel Arena booted`; client entry prints its own line.
- [x] `Shared/Config` (Debug, UseMockData flags), `Shared/Util/Log`, `Shared/Util/Trove` implemented — the only non-empty modules.
- [x] `tests/RunTests.luau` runner plus `tests/Trove.spec.luau`.
- [x] StyLua clean. Selene run with the generic `luau` std only (the `roblox` std needs Roblox's API dump, unreachable from the bootstrap environment); the only findings were the expected Roblox-global false positives. Run `selene src tests` on D's machine to confirm with the real std.
- [x] Docs seeded: DECISIONS, GAME_DESIGN, ROBLOX_PRIMER.

## D to do before P0 is closed (needs Studio on D's machine)

1. Install Rokit, `rokit install`, `rokit add JohnnyMorganz/luau-lsp`, commit `rokit.toml`. Confirm `rojo --version` is 7.7.0.
2. `rojo plugin install`.
3. New place in Studio, save to Roblox (private). Enable the built-in MCP server (Assistant → … → Manage MCP Servers → Enable → Quick connect → Claude Code).
4. `rojo serve`, Connect in Studio. Next Claude session: `list_roblox_studios`, `execute_luau` `print(game.PlaceId)`, Play, confirm `[Server] Duel Arena booted` in console.
5. Run the tests once from the command bar: `require(game:GetService("ServerStorage").Tests.RunTests)()` — expect `3 passed, 0 failed`.
6. Lobby scaffold (baseplate, SpawnLocation, `Pad_1v1`, `StarterPlayer.CameraMode = LockFirstPerson`) — Claude builds this via `execute_luau` once MCP is live.
7. Tag `v0.0.1` after the bootstrap PR merges.

## Next: P1 Core loop

Pads → queue → arena teleport; `DuelService` state machine; touch = kill placeholder damage; first to 5; back to lobby. Gate: two clients in Test mode complete a full 1v1 with no console errors.

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

None. Nothing has run in Studio yet.

## Notes

- `src/server/Vendor/ProfileStore.luau` is not vendored yet; it's not needed before P4 and GitHub was unreachable from the bootstrap environment.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` on a machine with GitHub access if it complains the std is missing.
