# Status

Updated 07/09/2026 (Session 2, first live Studio session). Full-auto run through the phases; D tests at the end.

## Phase progress

| Phase | State | Tag |
|---|---|---|
| P0 Bootstrap | done, gate passed | `v0.0.1` |
| P1 Core loop | done, gate passed (2-client duel to 5) | `v0.1.0` |
| P2 Weapons | done, gate passed (Mason feel test + exploit test) | `v0.2.0` |
| P3 Abilities | built, smoke-tested solo, **needs 2v2 gate** | pending `v0.3.0` |
| P4 Progression + data | in progress | |
| P5–P8 | not started | |

## P3 Abilities — built 07/09/2026

- `Shared/Config/Abilities.luau`: data-only definitions. Two per weapon, fixed loadout, E / F (gamepad L1 / R1).
  - Revolver: **Speed Loader** (instant refill, 12 s), **Dead Eye** (next shot ×2 within 4 s, gold crosshair, 15 s).
  - Knife: **Dash** (70 studs/s for 0.18 s, 6 s), **Second Wind** (+40 HP over 2 s, 18 s).
- `AbilityService`: cooldowns per player, reset every round, published as `Cooldown_<Id>` attributes (server timestamps); effects run server-side via `CombatService.refill` / `empowerNextShot` or the Humanoid. `UseAbility(slot)` is the only client→server remote (validated, 4/s). `AbilityUsed` fans out for VFX; the owner applies Dash movement locally (it owns its physics).
- `AbilityController`: bindings while armed, two HUD slot lines with live cooldown text, pulse VFX, Dash via a 0.18 s `LinearVelocity`.
- **No passive health regen**: Roblox's default `Health` script is removed from every character on spawn. Healing is Second Wind only.
- Tests: `Abilities.spec` (22 cases total across 7 spec files, all pass, now run inside Play so the Edit-mode cache can't lie).

### Verified solo via MCP

Speed Loader 4 → 6 with 11.7 s cooldown shown; Dead Eye → 70 body damage, crosshair gold, spent on the shot; Dash created the LinearVelocity and moved 21 studs; Second Wind healed 81 → 100 and went on an 18 s cooldown; cooldown attributes cleared on abort. Console clean.

### P3 gate (CLAUDE.md §7): all abilities work in a 2v2, cooldowns enforced server-side

Needs 4 clients (Test → Clients and Servers → 4). Two lobby pads are needed for 2v2: in Studio duplicate `Workspace.Lobby.Pad_1v1`, name it `Pad_2v2`, set its `TeamSize` attribute to 2, move it aside (e.g. x = 20). Matchmaking picks it up automatically. Then: all four onto the 2v2 pad; in the arena press E / F with each weapon; spam E and confirm the second press does nothing until the HUD says READY.

## P2 gate test notes (for reference)

Exploit test snippet (Play, any client command bar): expected no damage and one `[WARN]` on the server.

```lua
local r = game.ReplicatedStorage.Shared.Net.Remotes
local cam = workspace.CurrentCamera
local enemy = workspace:FindFirstChild("<opponent name>")
r.Fire:FireServer(cam.CFrame.Position, Vector3.new(0, 1, 0), enemy and enemy.Head, workspace:GetServerTimeNow())
r.Fire:FireServer("garbage")
```

## Known bugs / limitations

- Only solo smoke tests have run for P3; the 2v2 gate is outstanding.
- Viewmodel is grip-only with no fire/reload/swing animation. Sounds absent (P8).
- Lag tolerance is a fixed 3-stud corridor, not rollback. Revisit only if Mason reports missed hits.
- Dash magnitude is client-applied (the server only gates the cooldown). An exploiter could dash further, but they can already speedhack; anti-cheat for movement is out of scope for now.
- MCP `screen_capture` times out and, while the Studio window is unfocused, the Play client's camera doesn't render (RenderStepped stops), so camera-based tests must be driven from the character's head instead.

## Open questions for D (from CLAUDE.md §10)

Defaults were chosen for 2, 3, 4, 6 and 7; confirm or change them in `GAME_DESIGN.md`.

1. Working title.
2. ~~Team sizes at launch~~ → default: **1v1 first**; code supports all four via pad `TeamSize`.
3. ~~Round timer / sudden death~~ → default: **90 s, tie → sudden death, simultaneous wipe → draw**.
4. ~~Abilities~~ → default: **two per weapon, fixed** (Speed Loader, Dead Eye, Dash, Second Wind).
5. XP-only levels, or XP + soft currency for skins?
6. ~~Revolver / knife numbers~~ → default: **6 rounds, 35 body, ×2 head, 0.4 s, 1.6 s reload; knife 50 (two-hit), 6 studs**.
7. ~~Friendly fire~~ → default: **off**.
8. Art direction.
9. Launch platforms.
10. In-game "Lead Tester" credit for Mason?

## Notes

- **Setup snippet** (Edit DataModel) rebuilds the arena template and HUD from current code. Edit-mode `require` caches modules across runs, so it requires *clones*:

  ```lua
  local SS, SSS, RS, SG = game:GetService("ServerStorage"), game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage"), game:GetService("StarterGui")
  local function fresh(m) local c = m:Clone(); c.Parent = m.Parent; local r = require(c); c:Destroy(); return r end
  local t = SS:FindFirstChild("ArenaTemplates") or Instance.new("Folder", SS); t.Name = "ArenaTemplates"
  local AB = fresh(SSS.Server.ArenaBuilder); local old = t:FindFirstChild(AB.TemplateName); if old then old:Destroy() end
  AB.build().Parent = t
  local HL = fresh(RS.Shared.Util.HudLayout); local oh = SG:FindFirstChild(HL.Name); if oh then oh:Destroy() end
  HL.build().Parent = SG
  ```

- **Tests**: run inside Play (Server DataModel) for a fresh VM: `require(game.ServerStorage.Tests.RunTests)()`.
- **Driving a duel solo** (Play, Server DataModel): `game.ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"Name"}, {"Name"})`, `:Invoke("dummy", "Name", 10)`, `:Invoke("kill", "Name")`, `:Invoke("strikes", "Name")`, `:Invoke("abort", 1)`.
- `require` from the command bar / `execute_luau` returns a separate module instance from running scripts; in Edit mode it is also cached across runs.
- `execute_luau` prints go to Studio's Output window, not the tool result: `return` a string to read values back.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` if it complains the std is missing.
