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
| P6 Monetisation | built, receipt idempotency verified, **needs product ids + Studio test purchase** | pending `v0.6.0` |
| P7 Analytics + release prep | built, events verified firing, **needs a published test session** | pending `v0.7.0` |
| P8 Polish | done, gate passed | `v0.8.0` |
| Live-ops pass 1 | built, smoke-tested solo, **D to test** | pending `v0.9.0` |

**All eight roadmap phases passed their gates on 07/09/2026** (D's confirmation). Everything below the table is history plus the live-ops work that followed.

## Live-ops pass 1 — built 07/09/2026

- **Lobby pads for every mode**: `Pad_2v2` (green, x = +22), `Pad_3v3` (orange, x = −22), `Pad_4v4` (pink, x = +44) cloned from `Pad_1v1` in the place with their `TeamSize` attribute. Matchmaking registers all four.
- **Kill feed** (top right, 5 lines, 6 s): sent only to the duel's participants; green when you got the kill, red when you were the victim, knife icon and HEADSHOT tag.
- **Spectating**: dead in a live round (team modes) → third-person camera on a living teammate, else an opponent; "Spectating Name" in the notice line; back to first person on respawn. `DuelUpdate.roster` carries names and teams for this.
- **Touch controls**: FIRE / RELOAD / SWAP / E / F buttons appear when `UserInputService.TouchEnabled`.
- **Viewmodel animations**: reload dips and rolls for the reload duration; knife swing slashes an arc.

### Verified solo via MCP

Four pads registered; headshot + body shot killed the dummy and the kill feed showed `B3RZ3RK3R22 • TrainingDummy`; reload / swap / swing ran with the viewmodel intact and no client errors; three arenas rotate.

## Live-ops pass 2 — built 07/09/2026

- **Teammate outlines** (`TeamHighlightController`): in 2v2+ your teammates get a team-coloured outline visible through walls. Client-side only, so opponents never see yours.
- **AntiCheat, log-only** (`AntiCheatService`): flags impossible horizontal movement (WalkSpeed × 1.6, Dash-aware) with one `[WARN]` per player; `DebugCommands` `flags`. No enforcement yet by design (see DECISIONS).
- README gained a controls table. Verified solo: legitimate Dash → 0 flags, 60-stud teleport → 1 flag with the warning; no self-highlight; 37 tests pass.

### D to test (v0.9.0)

1. 2v2: die first and confirm you spectate your teammate, then snap back to first person at the next round. Your teammate should have a blue/orange outline.
0. After a few real duels, check the server Output for `AntiCheat:` warnings; any on honest players means the tolerance needs raising before enforcement is ever considered.
2. Kill feed colours: green for your kills, red when killed.
3. Reload and knife swing animations feel right (numbers in `client/Viewmodel.luau` `animOffset`).
4. If you have a phone or tablet: Studio → Test → Device emulation, check the touch buttons don't cover the HUD.

## P8 Polish — built 07/09/2026

- **Three arenas** (`ArenaBuilder.Variants`: Basic, Cross, Crates) sharing one shell; `Arena.acquire` picks a random template from `ServerStorage.ArenaTemplates` (rebuilt in the place). Duel logs show which (`Arena_Cross_1`).
- **Sound** (`Config/Sounds.luau`, `client/SoundController`): 16 events on Roblox built-in placeholders (fire, reload, reload done, swing, hit/headshot/kill, death, hurt, tick, fight, round won/lost, ability, dash, UI). 2D for your own actions, 3D for others' shots, deaths and abilities. All 16 verified loading in Studio after replacing two missing built-ins.
- **FX** (`FxController`): death poof (grey particles, no blood) + sound for every character, red damage tint + grunt on taking damage, centre announcements (3-2-1 ticks, FIGHT!, ROUND WON / LOST / DRAW, SUDDEN DEATH). HUD v4 adds `AnnounceLabel` and `DamageFlash`.
- Tests: `Polish.spec` (sound ids, arena variants build with 4+4 spawns, 4 walls, cover) — 37 cases, all pass inside Play.

### Verified solo via MCP

Three consecutive duels used `Arena_Basic`, `Arena_Cross`, `Arena_Basic`; a live round with 30 damage then a kill produced no client errors; 16/16 sounds report `IsLoaded` with a duration; HUD has the announce and flash elements.

### P8 gate (CLAUDE.md §7): release checklist complete; 60 fps on D's machine; bug bash with Mason's friends

1. **Performance pass** (D): a 2-client duel with Studio's MicroProfiler / Performance stats open; target < 16 ms client frame time, memory under 1 GB after 10 min. Report anything above and I'll profile the suspect (likely candidates: particle poofs, tracer parts, Heartbeat scans).
2. **Bug bash**: 4+ players, all three arenas, all abilities, locker and settings. Collect every oddity into STATUS → Known bugs.
3. Work through `docs/RELEASE_CHECKLIST.md`. Then D publishes (never Claude).

## P7 Analytics + release prep — built 07/09/2026

- `Shared/Config/Analytics.luau`: enabled flag, funnel step names (Joined, SteppedOnPad, FirstDuel, FirstWin), progression path `Level`, currency names.
- `AnalyticsService`: pcall-guarded wrapper; `funnel` (deduplicated per profile in `Profile.Data.Funnel`), `xpEarned` (economy source, sku DuelWin/DuelLoss), `levelReached` (progression complete), `boostPurchased` (economy IAP), `custom` (DuelWon / DuelLost with rounds won). Hooked in DataService load, Matchmaking join, DuelService start, ProgressionService rewards, MonetisationService grants.
- `docs/RELEASE_CHECKLIST.md`: place settings, maturity questionnaire draft (target **Mild**), data / monetisation / analytics / performance checks, go-public steps, post-launch watch items.
- Tests: `Analytics.spec` (35 cases, all pass inside Play).

### Verified solo via MCP

Console shows `AnalyticsService: … event fired` for funnel steps 1, 3, 4, an economy event for the boost, and progression + economy + custom events per duel. A second win did not re-record any funnel step. No `not recorded` lines.

### P7 gate (CLAUDE.md §7): D can see funnel data in Creator Hub after a test session; questionnaire drafted

Analytics only reaches Creator Hub from a published experience. Publish privately, play through join → pad → duel → win, then check Creator Hub → Analytics → Funnel / Economy / Progression per `docs/RELEASE_CHECKLIST.md` §5. Review the questionnaire draft in §2 of the checklist against the live form.

## P6 Monetisation — built 07/09/2026

- `Shared/Config/Monetisation.luau`: `SkinPasses` (RevolverVoid, KnifeVoid → pass id) and `DevProducts.XPBoost` (id, 30 min). **All ids are 0 until D creates the products**; the UI shows "Coming soon" / hides the boost row and the server refuses to prompt.
- `MonetisationService`: owns `ProcessReceipt` (idempotent via `Profile.Data.PurchaseHistory`, capped 50), grants game-pass skins on join and on purchase, prompts purchases server-side from `RequestPurchase(kind, key)`. Studio-only fake product id `999999001` for the harness.
- `Shared/Util/PurchaseLedger` (pure, tested). Locker: BUY rows for configured passes, XP boost row with ACTIVE countdown. `ProgressionSnapshot.boostUntil`.
- Tests: `PurchaseLedger.spec` (34 cases, all pass inside Play).

### Verified solo via MCP

`receipt A` → PurchaseGranted, boost +1800 s, history 1. `receipt A` again → PurchaseGranted, nothing changed (idempotent). `receipt B` → stacked to 3600 s, history 2. Unknown product → NotProcessedYet with one `[WARN]`. Forfeit win under boost → +200 XP (×2). Locker boost row reads `ACTIVE · 60 min left`; unconfigured `RequestPurchase` calls are ignored without errors.

### P6 gate (CLAUDE.md §7): test purchases in Studio work; a replayed receipt isn't granted twice; purchase state survives rejoin

D to do (CLAUDE.md §9: you create the products, I never touch the dashboard):
1. Creator Dashboard → your experience → Monetization: create two **Passes** ("Void Revolver", "Void Knife") and one **Developer Product** ("XP Boost ×2 (30 min)"). Copy the three ids.
2. Paste them into `src/shared/Config/Monetisation.luau` (`SkinPasses.RevolverVoid`, `SkinPasses.KnifeVoid`, `DevProducts.XPBoost.id`), commit.
3. Play in Studio (test purchases are free), open the Locker (L): BUY the boost → row turns ACTIVE; BUY a Void skin → it becomes EQUIP. Server Output shows `Monetisation: granted product …`.
4. Rejoin (stop/Play with API access on, as in the P4 gate) → boost time and skins persist. Replay protection is already proven by the harness.

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
  local AB = fresh(SSS.Server.ArenaBuilder); for _, old in t:GetChildren() do old:Destroy() end
  for _, m in AB.buildAll() do m.Parent = t end
  local HL = fresh(RS.Shared.Util.HudLayout); local oh = SG:FindFirstChild(HL.Name); if oh then oh:Destroy() end
  HL.build().Parent = SG
  ```

- **Tests**: run inside Play (Server DataModel) for a fresh VM: `require(game.ServerStorage.Tests.RunTests)()`.
- **Driving a duel solo** (Play, Server DataModel): `game.ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"Name"}, {"Name"})`, `:Invoke("dummy", "Name", 10)`, `:Invoke("kill", "Name")`, `:Invoke("strikes", "Name")`, `:Invoke("abort", 1)`, `:Invoke("profile", "Name")`, `:Invoke("addXP", "Name", 1500)`. `startDuel` with an empty second team is a forfeit win (fast XP path).
- MCP `execute_luau` calls are dispatched one after another even when requested in parallel: test a server→client event inside one client script (fire a remote, then listen), never across two calls.
- `require` from the command bar / `execute_luau` returns a separate module instance from running scripts; in Edit mode it is also cached across runs.
- `execute_luau` prints go to Studio's Output window, not the tool result: `return` a string to read values back.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` if it complains the std is missing.
