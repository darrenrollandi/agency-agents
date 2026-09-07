--!strict
-- HudController: health, weapon, ammo, crosshair and hit marker on DuelHud. LobbyController owns the
-- top lines (score, status, notices). Reads only what the server publishes: Humanoid health and the
-- Weapon / Ammo / Reloading attributes on the Player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Config.Weapons)
local Trove = require(Shared.Util.Trove)
local Hud = require(script.Parent.Parent.Hud)

export type HitKind = "hit" | "headshot" | "kill"

local player = Players.LocalPlayer

local HudController = {}

local healthLabel: TextLabel
local weaponLabel: TextLabel
local ammoLabel: TextLabel
local crosshair: GuiObject
local hitMarker: TextLabel
local characterTrove = Trove.new()
local hitToken = 0

local function renderWeapon()
	local weapon = player:GetAttribute("Weapon")
	if typeof(weapon) ~= "string" then
		weaponLabel.Text = ""
		ammoLabel.Text = ""
		crosshair.Visible = false
		return
	end
	crosshair.Visible = true
	weaponLabel.Text = string.upper(weapon)
	if weapon == "Revolver" then
		local ammo = player:GetAttribute("Ammo")
		if player:GetAttribute("Reloading") == true then
			ammoLabel.Text = "RELOADING"
		else
			ammoLabel.Text = `{tostring(ammo)} / {Weapons.Revolver.Cylinder}`
		end
	else
		ammoLabel.Text = ""
	end
end

local function bindCharacter(character: Model)
	characterTrove:clean()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	local function render()
		healthLabel.Text = tostring(math.max(0, math.ceil(humanoid.Health)))
	end
	characterTrove:connect(humanoid.HealthChanged, render)
	render()
end

-- Ammo shown immediately after a local shot; the server's Ammo attribute corrects it moments later.
function HudController.predictAmmo(ammo: number)
	if player:GetAttribute("Weapon") == "Revolver" and player:GetAttribute("Reloading") ~= true then
		ammoLabel.Text = `{ammo} / {Weapons.Revolver.Cylinder}`
	end
end

-- Flash the hit marker; bigger and coloured for headshots and kills.
function HudController.hitMarker(kind: HitKind)
	hitToken += 1
	local token = hitToken
	if kind == "kill" then
		hitMarker.TextColor3 = Color3.fromRGB(255, 80, 80)
		hitMarker.TextSize = 60
	elseif kind == "headshot" then
		hitMarker.TextColor3 = Color3.fromRGB(255, 210, 60)
		hitMarker.TextSize = 54
	else
		hitMarker.TextColor3 = Color3.new(1, 1, 1)
		hitMarker.TextSize = 44
	end
	hitMarker.TextTransparency = 0
	task.delay(if kind == "hit" then 0.12 else 0.3, function()
		if hitToken == token then
			hitMarker.TextTransparency = 1
		end
	end)
end

function HudController.start()
	healthLabel = Hud.element("HealthLabel") :: TextLabel
	weaponLabel = Hud.element("WeaponLabel") :: TextLabel
	ammoLabel = Hud.element("AmmoLabel") :: TextLabel
	crosshair = Hud.element("Crosshair")
	hitMarker = Hud.element("HitMarker") :: TextLabel

	for _, attribute in { "Weapon", "Ammo", "Reloading" } do
		player:GetAttributeChangedSignal(attribute):Connect(renderWeapon)
	end
	player.CharacterAdded:Connect(bindCharacter)
	local character = player.Character
	if character then
		bindCharacter(character)
	end
	renderWeapon()
end

return HudController
