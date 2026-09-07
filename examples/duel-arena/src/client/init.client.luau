--!strict
-- Client entry point. Order matters: the camera and HUD exist before weapons draw on them, and the
-- lobby lines come last. AbilityController and LockerController join in P3 and P4.
local CameraController = require(script.Controllers.CameraController)
local HudController = require(script.Controllers.HudController)
local WeaponController = require(script.Controllers.WeaponController)
local AbilityController = require(script.Controllers.AbilityController)
local LobbyController = require(script.Controllers.LobbyController)

CameraController.start()
HudController.start()
WeaponController.start()
AbilityController.start()
LobbyController.start()

print("[Client] Duel Arena client booted")
