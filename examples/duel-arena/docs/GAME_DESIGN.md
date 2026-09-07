# Game Design

Living design doc. Seeded 07/09/2026 from CLAUDE.md §2. Items marked **TBD** are open questions for D and Mason; answer them here, not in chat.

## Pitch

Fast-paced first-person dueling. Step on a pad, get thrown into an arena, win rounds until your team hits 5, land back in the lobby with XP and unlock progress. Rounds are short (target under 60 s). Getting back into the action fast matters more than anything.

## Core loop

1. Player lands in the **lobby**.
2. Player steps on a **duel pad** (one per team size). When the pad has enough players they are teleported into a free **arena**.
3. A **duel** is a series of **rounds**. A round ends when one team is fully eliminated. Winning team scores a point. **First to 5 wins the duel.**
4. Winners and losers return to the lobby. XP and unlock progress awarded.

## Team sizes

1v1, 2v2, 3v3, 4v4. **Default chosen 07/09/2026 (D to confirm):** 1v1 ships first. The code supports all four; adding a size is a new `Pad_*` part in the lobby with a `TeamSize` attribute (`src/shared/Config/Modes.luau`).

## Round rules

- Round ends when one team is fully eliminated.
- **Default chosen 07/09/2026 (D to confirm):** 90 s round timer. On expiry the team with more survivors wins; a tie becomes sudden death (no timer, next elimination decides). A simultaneous wipe is a draw and the round is replayed. All in `src/shared/Config/Rounds.luau`.
- **Default chosen 07/09/2026:** friendly fire off.
- Between rounds: 3 s frozen countdown at team spawns, full health (ammo and cooldowns reset from P2/P3), 3 s result pause. Duel result shown for 5 s before everyone returns to the lobby.
- Leaving mid-duel forfeits; the remaining team wins.

## Weapons

Everyone gets the same two weapons in every duel.

### Revolver

Hitscan, limited cylinder, reload.

Defaults chosen 07/09/2026 (D and Mason to tune in `src/shared/Config/Weapons.luau`):

| Stat | Value |
|---|---|
| Cylinder size | 6 |
| Damage per body shot | 35 (three body shots to kill) |
| Headshot multiplier | ×2 (70; head + body kills) |
| Fire interval | 0.4 s, semi-automatic |
| Reload time | 1.6 s; swapping cancels; empty click auto-reloads |
| Range | 400 studs |
| Recoil | 2.5° pitch kick, settles in ~0.3 s |

### Knife

Melee, fast, always available.

Defaults chosen 07/09/2026:

| Stat | Value |
|---|---|
| Kill | Two-hit (50 damage) |
| Swing interval | 0.45 s |
| Range | 6 studs, box 4.5 wide × 5 tall in front of the player |

Controls: left click fires or swings, R reloads, 1 / 2 select, Q toggles. Gamepad: R2 fire, X reload, Y swap. Everything goes through `ContextActionService`, so touch buttons are a flag away.

## Abilities

Each weapon has its own set of cooldown-based abilities. The framework is generic; the list is not fixed until D confirms.

- **TBD:** how many per weapon (assume 2–3)?
- **TBD:** picked before a duel as a loadout, or fixed for everyone?
- Design session with Mason: brainstorm 6–8 per weapon, pick the 2 that make the best "I outplayed you" moments.

### Revolver abilities (candidates)

_Empty until the design session._

### Knife abilities (candidates)

_Empty until the design session._

## Progression

Players unlock **knife skins** and **revolver skins** as they progress. Skins are cosmetic only.

- **TBD:** XP-only levels, or XP + soft currency for buying skins?
- XP curve: **TBD** (write as a table in `src/shared/Config/XP.luau` once decided).
- XP sources: duel win, duel loss (smaller), round wins, first duel of the day.

## Monetisation

Cosmetic only plus optional convenience. No pay-to-win.

- Skin game passes.
- One dev product (XP boost) as the first test of `ProcessReceipt`.

## Content maturity

Target label **Mild**. Stylised hits, no blood, bodies ragdoll briefly then despawn. Realistic blood or gore pushes the label to Moderate/Restricted and locks out the Kids 5–8 and Select 9–15 audiences.

## Platform and input

PC keyboard-mouse first. All gameplay input goes through `ContextActionService` with named actions (`Fire`, `Reload`, `SwapWeapon`, `Ability1`, `Ability2`) so touch and gamepad can be added without rewrites.

- **TBD:** launch platforms (PC only, or PC + mobile + console)?

## Art direction

- **TBD:** low-poly stylised vs blocky Roblox-default vs something else. Decide before any asset work.

## Maps

- Lobby: flat 128×128 floor, spawn at z = +30, one step-on pad per team size (`Pad_1v1` at z = −20 so far). Standing on a pad queues you; stepping off leaves.
- Arenas: 2–3 maps by P8. Instanced from `ServerStorage.ArenaTemplates` per duel into slots far from the lobby (x = 1000+). `Arena_Basic` (P1): 64×64 walled square, two centre pillars, teams spawn 48 studs apart facing each other.

## Credits

- **TBD:** in-game "Lead Tester" credit for Mason?

## Open questions

Mirrors CLAUDE.md §10. Strike each one out here as it's answered and move the answer into the relevant section above.

1. Working title.
2. ~~Team sizes at launch~~ — default 1v1 first (see Team sizes). Confirm.
3. ~~Round timer / sudden death~~ — default 90 s, tie → sudden death (see Round rules). Confirm.
4. Abilities: count and loadout vs fixed.
5. Progression currency.
6. ~~Revolver and knife numbers~~ — defaults in the Weapons tables. Tune after Mason's first P2 session.
7. ~~Friendly fire~~ — default off. Confirm.
8. Art direction.
9. Launch platforms.
10. Mason's credit.
