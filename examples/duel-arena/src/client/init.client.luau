--!strict
-- Client entry point. Bootstraps Controllers in order. P1 only needs LobbyController; the rest
-- (Camera → Weapon → Ability → Hud → Locker) come online in their phases.
local LobbyController = require(script.Controllers.LobbyController)

LobbyController.start()

print("[Client] Duel Arena client booted")
