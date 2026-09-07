# Status

Updated 07/09/2026 (Session 2, first live Studio session).

## Phase: P1 Core loop — built and smoke-tested solo, awaiting the 2-client gate test

P0 closed 07/09/2026 (commit `a827707`; tag `v0.0.1` still to be pushed, see Notes).

### Done this session

- **Net** (`Shared/Net`): remotes created from `Definitions.luau` at boot; client→server remotes must declare `ratePerSecond` + `validate` (enforced), bad payloads are dropped with a per-player strike counter and a single warn. `Util/RateLimiter` is a token bucket with injected clock.
- **Matchmaking** (`Services/MatchmakingService`): any `Workspace.Lobby.Pad_*` part with a numeric `TeamSize` attribute is a queue. **Stand on the pad to queue, step off to leave.** One overlap query per pad every 0.2 s. Full queue → teams dealt alternately → `DuelService.startDuel`. Pad label shows `1v1  1/2`.
- **Arenas** (`Arena.luau`, `ArenaBuilder.luau`): `ServerStorage.ArenaTemplates.Arena_Basic` (64×64 walled square, two pillars, 4 spawns per team) is cloned per duel into a slot at x = 1000 + 300·(slot−1), z = 1000, and destroyed on cleanup. If the template is missing the server rebuilds it from code with a warning.
- **DuelService**: `Waiting → Countdown → Live → RoundOver → (Countdown | DuelOver) → Cleanup`, every transition checked against `Shared/DuelRules` and logged. 3 s frozen countdown, 90 s round timer, tie on timer → sudden death, simultaneous wipe → draw (round replayed), first to 5. Leavers forfeit; an empty duel cleans itself up. `DuelService.abort(id)` tears one down.
- **CharacterService**: `Players.CharacterAutoLoads = false`; the service owns every spawn so a dead duelist stays dead until the next round. Lobby deaths respawn after 3 s.
- **CombatService**: P1 placeholder weapon is a server-side **Tag** Tool (red neon stick, auto-equipped when a round goes Live). Click → server box hitbox 7 studs in front → enemy `TakeDamage(100)`. No client code, no remotes, friendly fire off.
- **LobbyController** + `StarterGui.DuelHud` (built from `Shared/Util/HudLayout`): queue status, `Team B · A 0 - 0 B`, countdown / round clock / sudden death / VICTORY-DEFEAT, server notices.
- **Tests**: 14 cases across `Trove`, `DuelRules`, `RateLimiter`, `Modes` specs — all pass in Studio.
- **DebugCommands** (Studio only): `ServerStorage.DebugCommands` BindableFunction drives the *running* services from `execute_luau` (Server): `startDuel`, `abort`, `kill`, `state`, `activeDuels`.
- **Lobby changes in the place**: `Pad_1v1`'s ProximityPrompt removed (step-on queueing). `ServerStorage.ArenaTemplates.Arena_Basic` and `StarterGui.DuelHud` created.
- Repo: `.gitattributes` forces LF so StyLua passes on Windows; `rokit.toml` pins luau-lsp 1.69.0.

### Verified solo via MCP (Play Solo, one client)

- Boot: no warnings or errors. Pad registered, remotes created, auto-load off.
- Walk onto pad → queued (label `1v1  1/2`, HUD text, debug log). Walk off → dequeued.
- `startDuel` (same player on both teams as a stand-in): arena cloned, spawned at team spawn, frozen (WalkSpeed 0), Live after 3 s (WalkSpeed 16, Tag equipped), HUD `Round 1 · 1:08 · alive 1 - 1`, kill → RoundOver → next Countdown respawn at full health → abort → lobby, arena destroyed, 0 active duels.

## D to do: the P1 gate test

1. **Save the place (Ctrl+S) before anything else.** The arena template, the HUD and the pad-prompt removal live only in the open Studio session until saved. (If it's lost, the server rebuilds the arena and the client builds a fallback HUD, with warnings; the P1 setup snippet below restores the real ones.)
2. `rojo serve` running and connected. Studio **Test → Clients and Servers**, **2 players**, Start.
3. Both players walk onto the blue pad. Label should reach `1v1  2/2` and both should teleport to the arena within a second.
4. 3 s frozen countdown, then `Round 1 · 1:30`. Each player has the red Tag stick equipped; **left-click while facing the opponent within ~7 studs** eliminates them.
5. Round winner scores, 3 s pause, next round. Play to 5: `VICTORY` / `DEFEAT`, then back to the lobby after 5 s.
6. Also try: one client leaves mid-duel → the other should see `VICTORY  (opponent left)`.
7. Watch the **server** Output for `[WARN]` or red errors. Report: did teleport/respawn feel right, did Tag hits register, anything odd in the HUD.

**Gate passes when** two clients complete a full duel to 5 and land back in the lobby with no console errors. Then tag `v0.1.0`.

## Known bugs / limitations

- Only a same-player smoke test has run; a real 2-client duel is untested.
- Tag hitbox is a fixed box in front of the root part, not a swing animation. Fine for P1, replaced in P2.
- Respawn uses `LoadCharacter` + `PivotTo`; if a player ever appears at the lobby spawn for a frame before the arena, that's the engine re-placing the character (there's a deferred second pivot to cover it).
- MCP `screen_capture` times out in this session (Studio window not foregrounded). MCP-simulated keypresses don't reach ProximityPrompts (moot now that pads are step-on).

## Next

1. P1 gate test with D + Mason (above). Fix whatever it surfaces. Tag `v0.1.0`.
2. Answer the open questions below; move answers into `GAME_DESIGN.md`.
3. P2 Weapons: revolver (hitscan, cylinder, reload) + knife with server re-raycast, viewmodel, hit markers.

## Open questions for D (from CLAUDE.md §10)

Defaults were chosen for 2, 3 and 7 to unblock P1; confirm or change them in `GAME_DESIGN.md`.

1. Working title.
2. ~~Team sizes at launch~~ → default: **1v1 first**; code supports all four via pad `TeamSize`.
3. ~~Round timer / sudden death~~ → default: **90 s, tie → sudden death, simultaneous wipe → draw**.
4. Abilities per weapon (2–3?), loadout-picked or fixed?
5. XP-only levels, or XP + soft currency for skins?
6. Revolver: cylinder size, damage, headshot multiplier, reload time. Knife: one- or two-hit kill?
7. ~~Friendly fire~~ → default: **off**.
8. Art direction.
9. Launch platforms.
10. In-game "Lead Tester" credit for Mason?

## Notes

- Tag P0: `git tag v0.0.1 a827707 && git push origin v0.0.1`.
- **P1 setup snippet** (Edit DataModel, `execute_luau` or command bar) rebuilds the arena template and HUD if the place wasn't saved:

  ```lua
  local SS, SSS, RS, SG = game:GetService("ServerStorage"), game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage"), game:GetService("StarterGui")
  local t = SS:FindFirstChild("ArenaTemplates") or Instance.new("Folder", SS); t.Name = "ArenaTemplates"
  local AB = require(SSS.Server.ArenaBuilder); local old = t:FindFirstChild(AB.TemplateName); if old then old:Destroy() end
  AB.build().Parent = t
  local HL = require(RS.Shared.Util.HudLayout); local oh = SG:FindFirstChild(HL.Name); if oh then oh:Destroy() end
  HL.build().Parent = SG
  ```

- **Driving a duel solo** (Play, `execute_luau` on the Server DataModel): `game.ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"Name"}, {"Name"})`, then `:Invoke("kill", "Name")`, `:Invoke("abort", 1)`.
- `require` from the command bar / `execute_luau` returns a **separate module instance** from the running server scripts (its own upvalues). Use `DebugCommands` to reach live state.
- `execute_luau` prints go to Studio's Output window, not the tool result: `return` a string to read values back.
- `src/server/Vendor/ProfileStore.luau` is not vendored yet; not needed before P4.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` if it complains the std is missing.
