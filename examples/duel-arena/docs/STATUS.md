# Status

Updated 07/09/2026 (Session 2, first live Studio session). Full-auto run through the phases; D tests at the end.

## Phase progress

| Phase | State | Tag |
|---|---|---|
| P0 Bootstrap | done, gate passed | `v0.0.1` |
| P1 Core loop | done, gate passed (2-client duel to 5) | `v0.1.0` |
| P2 Weapons | done, gate passed (Mason feel test + exploit test) | `v0.2.0` |
| P3 Abilities | built, smoke-tested solo, **needs 2v2 gate** | pending `v0.3.0` |
| P4 Progression + data | built, smoke-tested solo, **needs rejoin + session-lock gate** | pending `v0.4.0` |
| P5 UI/UX | built, smoke-tested solo, **needs Mason navigation gate** | pending `v0.5.0` |
| P6 Monetisation | in progress | |
| P7–P8 | not started | |

## P5 UI/UX — built 07/09/2026

- **HUD v3** (`StarterGui.DuelHud`, rebuilt from `HudLayout`): everything from P2/P3 plus
  - `LobbyPanel` (outside duels): `LEVEL 2 · 350 / 600 XP` and the hint *Stand on the blue pad to duel · [L] Locker · [Tab] Settings*.
  - `ResultsPanel` (DuelOver → Cleanup): VICTORY / DEFEAT / DRAW, your score vs theirs (+ "opponent left" on forfeit), `+100 XP · Level 2 ▲ LEVEL UP`, `Unlocked: Blued Steel · equip it in the Locker`.
  - `SettingsPanel` (Tab / gamepad Start): Sensitivity 0.2–3.0 and Field of view 60–100 with ◄ ► buttons; keyboard ↑ ↓ picks a row, ← → adjusts. Applies instantly, saves to the profile after 0.6 s (`SaveSettings`, range-validated), loads on join.
- `client/MouseFree`: ref-counted cursor release shared by the locker and settings.
- `Hud.element` searches recursively; every HUD element name is unique. Panels expose an `Open` attribute.
- Server sends the DuelOver update before `DuelReward` so the panel is open when the reward lands.
- Tests: SaveSettings validator (31 cases, all pass inside Play).

### Verified solo via MCP

Lobby panel visible with level line and hint; settings opens/closes via attribute, rows render `▸ Sensitivity 1.0` / `Field of view 80`, FOV and MouseDeltaSensitivity applied; `SaveSettings(1.5, 90)` persisted to the profile; forfeit duel → results panel with VICTORY, score, XP line with LEVEL UP and the unlock line; back to the lobby panel after Cleanup.

### P5 gate (CLAUDE.md §7): Mason can navigate everything without asking D

Hand Mason the game cold: find the pad, duel, read the result, open the Locker (L), equip a skin, open Settings (Tab), change sensitivity. Note every moment he asks a question; each one is a UI fix.

## P4 Progression + data — built 07/09/2026

- **ProfileStore** vendored at `src/server/Vendor/ProfileStore.luau` (upstream main; excluded from StyLua/Selene).
- **DataService**: one session-locked profile per player (`Player_<UserId>` in store `PlayerData_v1`), `Reconcile` against `Shared/Config/ProfileTemplate`, `AddUserId` for GDPR, kick on load failure or stolen session, `EndSession` on leave. In Studio `Config.UseMockData` selects `store.Mock`: nothing touches live DataStores. Expected Studio console lines: `StudioAccessToApisNotAllowed` + `[ProfileStore]: Roblox API services unavailable` (its availability probe; the Mock is working).
- **ProfileTemplate** v1: XP, Wins, Losses, Duels, RoundsWon, OwnedSkins, EquippedRevolver/Knife, PurchaseHistory, XPBoostUntil, Settings (Sensitivity, FOV), FirstJoin/LastJoin, Funnel.
- **ProgressionService**: XP curve `50·L·(L+1)` (`Config/XP.luau`), rewards 100 win / 40 loss / +10 per round, ×2 under boost. Level-up grants skins (`Config/Skins.luau`: 5 per weapon, level 2/5/8 and 3/6/10 plus a Void game-pass skin each). Publishes `XP`, `Level`, `EquippedRevolver`, `EquippedKnife` attributes and a `ProgressionSnapshot`; sends `DuelReward` after each duel. `EquipSkin` remote validated (owned + known). Nobody can queue before their profile is loaded.
- **Skins applied**: `WeaponModels.build(weapon, anchored, skinId)` paints the same geometry; the server's hand model and the client viewmodel both read the equipped attribute and re-skin live.
- **Locker** (`LockerController`, built in code): L / gamepad Select in the lobby, two columns, swatches, EQUIPPED / EQUIP / Level N / Shop (soon), click to equip. Also opens via the `Open` attribute on `PlayerGui.LockerGui` (for the P5 lobby menu and tests).
- DebugCommands: `profile`, `addXP`.
- Tests: `XP.spec`, `Skins.spec` (29 cases, all pass inside Play).

### Verified solo via MCP

Mock profile loads (FirstJoin set, defaults owned); `addXP 1500` → level 5, unlocked Blued/Gold/Jade, attributes and snapshot updated; forfeit duel → +100 XP, Wins 1, `DuelReward` received on the client; `EquipSkin RevolverGold` → attribute, snapshot, server world model built with `Skin=RevolverGold`; `EquipSkin KnifeNeon` (unowned) refused; locker renders correct rows and statuses, opens/closes.

### P4 gate (CLAUDE.md §7): leave and rejoin keeps XP, level, equipped skins; session lock tested with two Studio instances

Mock data resets every Play session by design, so the gate needs the **published place** or Studio with API access:
1. **Persistence**: in a Studio session with *Enable Studio Access to API Services* ON (Game Settings → Security), set `Config.UseMockData` to `false` temporarily (`src/shared/Config/init.luau`), Play, win a duel or `addXP`, equip a skin, stop, Play again → level and skins should persist. Turn API access back off afterwards (CLAUDE.md §6).
2. **Session lock**: open the place in two Studio instances with API access on, Play in both with the same account → the second load should kick with "Your data was opened on another server".
3. Check the mouse is free (cursor visible, panel clickable) while the locker is open, and locked again on close.

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
5. ~~XP-only or XP + currency~~ → default: **XP-only** (see GAME_DESIGN → Progression).
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
- **Driving a duel solo** (Play, Server DataModel): `game.ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"Name"}, {"Name"})`, `:Invoke("dummy", "Name", 10)`, `:Invoke("kill", "Name")`, `:Invoke("strikes", "Name")`, `:Invoke("abort", 1)`, `:Invoke("profile", "Name")`, `:Invoke("addXP", "Name", 1500)`. `startDuel` with an empty second team is a forfeit win (fast XP path).
- MCP `execute_luau` calls are dispatched one after another even when requested in parallel: test a server→client event inside one client script (fire a remote, then listen), never across two calls.
- `require` from the command bar / `execute_luau` returns a separate module instance from running scripts; in Edit mode it is also cached across runs.
- `execute_luau` prints go to Studio's Output window, not the tool result: `return` a string to read values back.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` if it complains the std is missing.
