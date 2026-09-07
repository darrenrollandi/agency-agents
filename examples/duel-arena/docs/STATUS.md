# Status

Updated 07/09/2026 (Session 2, first live Studio session).

## Phase: P2 Weapons — built and smoke-tested solo, awaiting Mason's feel test

- P0 closed 07/09/2026 → `v0.0.1`.
- P1 closed 07/09/2026 → `v0.1.0` (2-client duel to 5 with no errors, confirmed by D).
- P2 built 07/09/2026; gate needs Mason (see below).

### Done in P2

- **Revolver** (`CombatService`): hitscan, 6-round cylinder, 35 body / 70 head, 0.4 s between shots, 1.6 s reload, 400-stud range. The client raycasts for instant feedback and sends `{origin, direction, hitPart?, timestamp}`; the server checks armed + alive, origin within 8 studs of the head, fire interval, ammo and reload state, then **re-raycasts** and only its own ray decides. Basic lag tolerance: if the server ray misses, a claimed victim whose root lies within 3 studs of the ray with nothing solid in between counts as a body hit.
- **Knife**: server box hitbox 6 studs in front of the root, 50 damage (two-hit kill), 0.45 s between swings. Facing-gated by construction.
- **Swap** (1 / 2 / Q, gamepad Y), **reload** (R / X). Swapping cancels a reload. Empty click auto-reloads.
- **No Tools.** Loadout state lives in `CombatService` and is published as Player attributes `Weapon`, `Ammo`, `Reloading`; the client reads those. Default backpack UI disabled.
- **Third-person weapon** welded to the right hand so opponents see what you hold. **Viewmodel** (blocky revolver / knife from `Shared/WeaponModels`) parented to the Camera, with fire kick, bob and sway. **Recoil** pitch kick that settles. FOV 80.
- **Effects**: muzzle flash, tracer, impact dot; other players' shots draw tracers via an `UnreliableRemoteEvent`.
- **HUD v2** (`StarterGui.DuelHud`, rebuilt): health bottom-left, weapon + ammo / RELOADING bottom-right, crosshair dot, hit marker (white hit, yellow headshot, red kill).
- **Death**: disarmed on death, body removed after 2 s, fresh character at full health next round.
- **Net**: `Fire` / `Reload` / `Swing` / `Equip` are the first client→server remotes; each has a pure validator (NaN / non-unit / wrong-type payloads are dropped with a strike) and a rate limit 25% above the weapon cadence.
- **Training dummies**: non-player humanoids are always hittable, so hit-reg can be tested solo (`DebugCommands` `dummy`).
- Tests: `Validators.spec` added (6 spec files, all pass).

### Verified solo via MCP (Play Solo)

- Legit headshot → HitConfirm 70, ammo 6→5. Body shot → 35, kill. Knife ×2 → 50 + 50 kill.
- **Exploit checks**: spoofed origin 60 studs away → dropped, no ammo used. Aim at the sky while claiming the dummy's head as `hitPart` → no hit, ammo used. Malformed payload → dropped, strike counted (1), one `[WARN]`.
- Reload → `RELOADING` on HUD, 6/6 after 1.6 s. Swap → attribute, HUD and viewmodel follow.
- Real input path: Q swapped weapons, a simulated left click fired (6→5).
- Death → disarmed, corpse gone at 2 s, respawn 100 HP, re-armed at Live. Abort → lobby, arena destroyed.

## D and Mason to do: the P2 gate test

1. **Save the place (Ctrl+S).** `StarterGui.DuelHud` and `ServerStorage.ArenaTemplates.Arena_Basic` were rebuilt this session.
2. **Test → Clients and Servers, 2 players.** Both onto the pad. In the arena: left-click fires, R reloads, Q or 1/2 swaps, knife on 2.
3. Gate (CLAUDE.md §7): Mason plays a 1v1 vs D and says it **feels good**; no "I clearly hit him" complaints in 10 rounds; and the exploit test below does nothing.
4. **Exploit test** (Play, any client window, command bar):
   ```lua
   local r = game.ReplicatedStorage.Shared.Net.Remotes
   local cam = workspace.CurrentCamera
   -- claim a hit on the opponent while aiming at the sky
   local enemy = workspace:FindFirstChild("<opponent name>")
   r.Fire:FireServer(cam.CFrame.Position, Vector3.new(0, 1, 0), enemy and enemy.Head, workspace:GetServerTimeNow())
   r.Fire:FireServer("garbage") -- expect one [WARN] Net: dropped ... on the server
   ```
   Expected: opponent takes no damage; server Output shows a single `[WARN]` for the garbage payload.
5. Report: does the revolver feel snappy or floaty, is 35/70 damage right, is the knife range fair, does the reload feel long, anything odd with the viewmodel or recoil. Numbers are all in `src/shared/Config/Weapons.luau` and `Config/Camera.luau`.

## Known bugs / limitations

- Only solo smoke tests have run for P2; a real 2-client feel test is outstanding.
- Viewmodel is grip-only (no arms) and has no fire/reload/swing animation. Sounds absent (P8).
- Lag tolerance is a fixed 3-stud corridor, not rollback. Revisit only if Mason reports missed hits.
- Head detection is by part name `Head`; fine for R6/R15 and dummies.
- MCP `screen_capture` times out in this session (Studio window not foregrounded).

## Next

1. P2 gate with Mason. Tune `Config/Weapons.luau` from feedback. Tag `v0.2.0`.
2. Answer open questions 1, 4, 5, 8, 9, 10 (below); the design session for abilities.
3. P3 Abilities: generic framework (cooldowns server-side, client VFX), first two abilities per weapon.

## Open questions for D (from CLAUDE.md §10)

Defaults were chosen for 2, 3, 6 and 7; confirm or change them in `GAME_DESIGN.md`.

1. Working title.
2. ~~Team sizes at launch~~ → default: **1v1 first**; code supports all four via pad `TeamSize`.
3. ~~Round timer / sudden death~~ → default: **90 s, tie → sudden death, simultaneous wipe → draw**.
4. Abilities per weapon (2–3?), loadout-picked or fixed?
5. XP-only levels, or XP + soft currency for skins?
6. ~~Revolver / knife numbers~~ → default: **6 rounds, 35 body, ×2 head, 0.4 s, 1.6 s reload; knife 50 (two-hit), 6 studs**.
7. ~~Friendly fire~~ → default: **off**.
8. Art direction.
9. Launch platforms.
10. In-game "Lead Tester" credit for Mason?

## Notes

- **Setup snippet** (Edit DataModel) rebuilds the arena template and HUD from the current code if the place wasn't saved. Edit-mode `require` caches modules across runs, so it requires *clones*:

  ```lua
  local SS, SSS, RS, SG = game:GetService("ServerStorage"), game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage"), game:GetService("StarterGui")
  local function fresh(m) local c = m:Clone(); c.Parent = m.Parent; local r = require(c); c:Destroy(); return r end
  local t = SS:FindFirstChild("ArenaTemplates") or Instance.new("Folder", SS); t.Name = "ArenaTemplates"
  local AB = fresh(SSS.Server.ArenaBuilder); local old = t:FindFirstChild(AB.TemplateName); if old then old:Destroy() end
  AB.build().Parent = t
  local HL = fresh(RS.Shared.Util.HudLayout); local oh = SG:FindFirstChild(HL.Name); if oh then oh:Destroy() end
  HL.build().Parent = SG
  ```

- **Driving a duel solo** (Play, `execute_luau` on the Server DataModel): `game.ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"Name"}, {"Name"})`, then `:Invoke("dummy", "Name", 10)` for a target, `:Invoke("kill", "Name")`, `:Invoke("strikes", "Name")`, `:Invoke("abort", 1)`.
- `require` from the command bar / `execute_luau` returns a **separate module instance** from running scripts, and in Edit mode that instance is **cached across runs**. Use `DebugCommands` for live state and the clone trick for fresh source.
- `execute_luau` prints go to Studio's Output window, not the tool result: `return` a string to read values back.
- `src/server/Vendor/ProfileStore.luau` is not vendored yet; not needed before P4.
- Selene's `roblox` std needs a one-off `selene generate-roblox-std` if it complains the std is missing.
