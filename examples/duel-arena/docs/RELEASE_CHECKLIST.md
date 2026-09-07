# Release checklist

Drafted 07/09/2026 (P7). D does everything on the Creator Dashboard and publishes; Claude never publishes (CLAUDE.md §9). Tick items in this file as they're done.

## 1. Place and experience settings (Creator Dashboard → your experience)

- [ ] **Name / description / icon / thumbnails.** Working title still open (GAME_DESIGN.md → Open questions 1). Description should say "1v1 to 4v4 first-person duels, revolver and knife, first to 5 rounds". Keywords: duel, 1v1, arena, revolver, PvP.
- [ ] **Genre**: Shooter (sub-genre Arena / Battle) or Fighting. Pick one; it drives discovery.
- [ ] **Max players**: 10 (four 1v1s in flight plus lobby traffic; `Config/Rounds.MaxArenas = 8`). Server fill: default.
- [ ] **Avatar**: R15 (default). Animations default. No forced body scales.
- [ ] **Voice chat**: off for launch (Mild label + young audience).
- [ ] **Text chat**: Roblox TextChatService default (filtered). No custom chat.
- [ ] **Security → Enable Studio Access to API Services**: **OFF** (CLAUDE.md §6). Turn on only for a P4 gate session, then off again.
- [ ] **Security → Allow HTTP Requests**: off. **Allow Third Party Sales**: off.
- [ ] **Private servers**: off for launch (revisit with demand).
- [ ] **Age guidelines / maturity questionnaire**: answer per §2 below. Target label **Mild**.
- [ ] **Paid access**: off.
- [ ] **Monetization**: create the two Passes and the Developer Product from GAME_DESIGN.md → Monetisation, paste ids into `src/shared/Config/Monetisation.luau`, set prices.
- [ ] **Places**: one start place. `StreamingEnabled` stays on (default); arenas sit 1000+ studs from the lobby and stream in as players teleport.

## 2. Maturity questionnaire — draft answers (D to confirm against the live form)

Reference: https://create.roblox.com/docs/production/promotion/content-maturity. Answers reflect the game as built; revisit if content changes (blood, gore, gambling mechanics would each move the label).

| Question area | Draft answer | Why |
|---|---|---|
| Violence | **Yes, mild**: unrealistic, stylised combat with weapons (blocky revolver and knife), no blood, bodies vanish after 2 s. | `Rounds.CorpseSeconds = 2`, no blood effects anywhere, hit marker and neon tracer only. |
| Blood | **No.** | None rendered. Keep it that way (P8 VFX must not add blood). |
| Fear / horror | **No.** | No jump scares, gore or horror themes. |
| Crude humour | **No.** | None. |
| Romance / sexual content | **No.** | None. |
| Alcohol, drugs, tobacco | **No.** | None. |
| Gambling / paid random items | **No.** | Purchases are fixed items (a specific skin, a timed XP boost). No loot boxes, no randomness. |
| Strong language | **No.** | No custom text beyond UI strings; Roblox chat filter applies. |
| Free-form user creation | **No.** | Players cannot create or upload content. |
| Social features | Text chat via Roblox default; no voice. | Standard. |
| In-experience purchases | **Yes**: cosmetic skins and an XP boost. | GAME_DESIGN.md → Monetisation. |

Expected result: **Mild** (suitable for Kids 5–8 with parental controls and Select 9–15). Anything above Mild is a bug in either the game or this table.

## 3. Data

- [ ] `Config.UseMockData` is `RunService:IsStudio()` (never hard-coded true) so the published server uses the real store `PlayerData_v1`.
- [ ] P4 gate passed: persistence across rejoin and session-lock kick both observed.
- [ ] `ProfileTemplate.Version` is 1. Any field change after launch bumps it and adds a migration note in DECISIONS.md.
- [ ] GDPR: `Profile:AddUserId` is called on load, so right-to-erasure requests can be honoured with the ProfileStore tooling.

## 4. Monetisation

- [ ] Ids pasted, prices set, P6 gate passed (test purchase works, replay not granted twice, survives rejoin).
- [ ] Prices documented in GAME_DESIGN.md.
- [ ] Nothing purchasable affects combat (only skins and XP rate). Re-check whenever a product is added.

## 5. Analytics (P7 gate: funnel visible in Creator Hub after a test session)

- [ ] Publish (private is fine) and play one session: join → step on the pad → finish a duel → win one.
- [ ] Creator Hub → Analytics → **Funnel**: onboarding funnel shows steps 1–4 (Joined, SteppedOnPad, FirstDuel, FirstWin) with the test player.
- [ ] **Economy**: currency `XP` sources (DuelWin / DuelLoss) appear; `BoostMinutes` appears after a test boost purchase.
- [ ] **Progression**: path `Level` shows completes.
- [ ] Custom events `DuelWon` / `DuelLost` appear.
- [ ] Nothing in the server log says `Analytics: … not recorded` (that line only appears with `Config.Debug`).

## 6. Performance (P8 gate: 60 fps on D's machine)

- [ ] Studio → View → Performance / MicroProfiler during a 2-client duel: frame time under 16 ms on the client, server heartbeat comfortable.
- [ ] Memory: Developer Console → Memory under 1 GB client after 10 minutes.
- [ ] No `[WARN]` spam in a 10-minute session (rate-limit warnings appear once per player by design).

## 7. Before flipping to public

- [ ] All phase gates in `docs/STATUS.md` passed; tags `v0.1.0` … `v0.8.0` pushed.
- [ ] Bug bash with Mason's friends done (P8) and the found issues fixed or listed in STATUS.md → Known bugs.
- [ ] `Config.Debug` is `RunService:IsStudio()` so `DebugCommands` never exists on a live server (it checks `Config.Debug`).
- [ ] Back up the place: File → Save to Roblox As… (a dated copy) before the first public publish.
- [ ] Publish from Studio (D). Set the experience to Public on the dashboard (D).

## 8. After launch

- [ ] Watch Creator Hub funnel drop-off between steps 2 and 3 (pad → first duel): if high, the queue needs bots or a solo mode.
- [ ] Watch `Level` progression pacing against `Config/XP.luau`; tune rewards, not the curve, first.
- [ ] Review any DataStore error spikes (Creator Hub → Monitoring).
