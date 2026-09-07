--!strict
-- Client entry point. Order matters: the camera and HUD exist before weapons draw on them, and the
-- lobby lines come last. AbilityController and LockerController join in P3 and P4.
local CameraController = require(script.Controllers.CameraController)
local HudController = require(script.Controllers.HudController)
local FxController = require(script.Controllers.FxController)
local WeaponController = require(script.Controllers.WeaponController)
local AbilityController = require(script.Controllers.AbilityController)
local LobbyController = require(script.Controllers.LobbyController)
local LockerController = require(script.Controllers.LockerController)
local SettingsController = require(script.Controllers.SettingsController)
local SpectateController = require(script.Controllers.SpectateController)
local TeamHighlightController = require(script.Controllers.TeamHighlightController)

CameraController.start()
HudController.start()
FxController.start()
WeaponController.start()
AbilityController.start()
LobbyController.start()
LockerController.start()
SettingsController.start()
SpectateController.start()
TeamHighlightController.start()

print("[Client] Duel Arena client booted")
