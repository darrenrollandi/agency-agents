--!strict
-- WeaponController: input via ContextActionService, local prediction (viewmodel kick, recoil, flash,
-- tracer, provisional hit marker, predicted ammo) and the Fire / Swing / Reload / Equip requests.
-- The server decides everything that matters; this file only makes it feel instant.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Weapons = require(Shared.Config.Weapons)
local CameraConfig = require(Shared.Config.Camera)
local Net = require(Shared.Net.Net)
local Viewmodel = require(script.Parent.Parent.Viewmodel)
local Effects = require(script.Parent.Parent.Effects)
local SoundController = require(script.Parent.Parent.SoundController)
local CameraController = require(script.Parent.CameraController)
local HudController = require(script.Parent.HudController)

local ACTION_FIRE = "Fire"
local ACTION_RELOAD = "Reload"
local ACTION_REVOLVER = "EquipRevolver"
local ACTION_KNIFE = "EquipKnife"
local ACTION_SWAP = "SwapWeapon"
local BIND_NAME = "DuelArenaViewmodel"

local player = Players.LocalPlayer

local WeaponController = {}

local viewmodel = Viewmodel.new()
-- What we hold locally; nil while disarmed. Follows the server's Weapon attribute.
local weapon: Types.WeaponId? = nil
local predictedAmmo = 0
local lastFireAt = 0
local lastSwingAt = 0
local bound = false

local function serverAmmo(): number
	local ammo = player:GetAttribute("Ammo")
	return if typeof(ammo) == "number" then ammo else 0
end

local function isReloading(): boolean
	return player:GetAttribute("Reloading") == true
end

local function hitsHumanoid(instance: Instance?): boolean
	local model = if instance then instance:FindFirstAncestorOfClass("Model") else nil
	return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function equippedSkin(target: Types.WeaponId): string?
	local skin = player:GetAttribute(`Equipped{target}`)
	return if typeof(skin) == "string" then skin else nil
end

local function showWeapon(target: Types.WeaponId?)
	viewmodel:setWeapon(target, if target then equippedSkin(target) else nil)
end

local function equip(target: Types.WeaponId)
	if weapon == target then
		return
	end
	weapon = target
	showWeapon(target)
	Net.fireServer("Equip", target)
end

local function fireRevolver()
	local now = os.clock()
	if now - lastFireAt < Weapons.Revolver.FireInterval or isReloading() then
		return
	end
	if predictedAmmo <= 0 then
		Net.fireServer("Reload") -- empty click reloads
		SoundController.play("Reload")
		viewmodel:playReload(Weapons.Revolver.ReloadSeconds)
		return
	end
	lastFireAt = now
	predictedAmmo -= 1
	HudController.predictAmmo(predictedAmmo)

	local camera = Workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { camera }
	if player.Character then
		table.insert(exclude, player.Character :: Instance)
	end
	params.FilterDescendantsInstances = exclude
	local result = Workspace:Raycast(origin, direction * Weapons.Revolver.MaxRange, params)
	local hitPart: Instance? = if result then result.Instance else nil
	local hitPosition = if result
		then result.Position
		else origin + direction * Weapons.Revolver.MaxRange

	-- Instant feedback; the server's HitConfirm is the real verdict.
	viewmodel:kick(CameraConfig.ViewmodelKick)
	CameraController.kick(CameraConfig.RecoilPitchDegrees)
	local muzzle = viewmodel:muzzlePosition() or origin
	Effects.flash(muzzle)
	SoundController.play("Fire")
	Effects.tracer(muzzle, hitPosition)
	if result then
		Effects.impact(hitPosition)
	end
	if hitsHumanoid(hitPart) then
		HudController.hitMarker("hit")
	end

	Net.fireServer("Fire", origin, direction, hitPart, Workspace:GetServerTimeNow())
end

local function swingKnife()
	local now = os.clock()
	if now - lastSwingAt < Weapons.Knife.SwingInterval then
		return
	end
	lastSwingAt = now
	viewmodel:playSwing(Weapons.Knife.SwingInterval * 0.7)
	SoundController.play("Swing")
	Net.fireServer("Swing")
end

local function onAction(actionName: string, inputState: Enum.UserInputState, _input: InputObject)
	local held = weapon
	if inputState ~= Enum.UserInputState.Begin or not held then
		return Enum.ContextActionResult.Pass
	end
	if actionName == ACTION_FIRE then
		if held == "Revolver" then
			fireRevolver()
		else
			swingKnife()
		end
	elseif actionName == ACTION_RELOAD then
		if
			held == "Revolver"
			and not isReloading()
			and predictedAmmo < Weapons.Revolver.Cylinder
		then
			Net.fireServer("Reload")
			SoundController.play("Reload")
			viewmodel:playReload(Weapons.Revolver.ReloadSeconds)
		end
	elseif actionName == ACTION_REVOLVER then
		equip("Revolver")
	elseif actionName == ACTION_KNIFE then
		equip("Knife")
	elseif actionName == ACTION_SWAP then
		equip(if held == "Revolver" then "Knife" else "Revolver")
	end
	return Enum.ContextActionResult.Sink
end

local function bind()
	if bound then
		return
	end
	bound = true
	-- On touch devices ContextActionService draws a button per action; titles keep them readable.
	local touch = UserInputService.TouchEnabled
	ContextActionService:BindAction(
		ACTION_FIRE,
		onAction,
		touch,
		Enum.UserInputType.MouseButton1,
		Enum.KeyCode.ButtonR2
	)
	ContextActionService:BindAction(
		ACTION_RELOAD,
		onAction,
		touch,
		Enum.KeyCode.R,
		Enum.KeyCode.ButtonX
	)
	ContextActionService:BindAction(ACTION_REVOLVER, onAction, false, Enum.KeyCode.One)
	ContextActionService:BindAction(ACTION_KNIFE, onAction, false, Enum.KeyCode.Two)
	ContextActionService:BindAction(
		ACTION_SWAP,
		onAction,
		touch,
		Enum.KeyCode.Q,
		Enum.KeyCode.ButtonY
	)
	if touch then
		ContextActionService:SetTitle(ACTION_FIRE, "FIRE")
		ContextActionService:SetPosition(ACTION_FIRE, UDim2.new(1, -110, 1, -160))
		ContextActionService:SetTitle(ACTION_RELOAD, "RELOAD")
		ContextActionService:SetPosition(ACTION_RELOAD, UDim2.new(1, -190, 1, -100))
		ContextActionService:SetTitle(ACTION_SWAP, "SWAP")
		ContextActionService:SetPosition(ACTION_SWAP, UDim2.new(1, -190, 1, -220))
	end
end

local function unbind()
	if not bound then
		return
	end
	bound = false
	for _, name in { ACTION_FIRE, ACTION_RELOAD, ACTION_REVOLVER, ACTION_KNIFE, ACTION_SWAP } do
		ContextActionService:UnbindAction(name)
	end
end

-- The server's Weapon attribute is the truth: present = armed with that weapon, absent = disarmed.
local function onWeaponAttribute()
	local serverWeapon = player:GetAttribute("Weapon")
	if serverWeapon == "Revolver" or serverWeapon == "Knife" then
		weapon = serverWeapon :: Types.WeaponId
		showWeapon(weapon)
		predictedAmmo = serverAmmo()
		bind()
	else
		weapon = nil
		showWeapon(nil)
		unbind()
	end
end

function WeaponController.start()
	-- Weapons are not Tools, so the default backpack bar would only confuse.
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	player:GetAttributeChangedSignal("Weapon"):Connect(onWeaponAttribute)
	player:GetAttributeChangedSignal("Ammo"):Connect(function()
		predictedAmmo = serverAmmo()
	end)
	-- Equipping a skin in the locker re-skins the viewmodel if that weapon is in hand.
	player:GetAttributeChangedSignal("Reloading"):Connect(function()
		if player:GetAttribute("Reloading") == false and weapon == "Revolver" then
			SoundController.play("ReloadDone")
		end
	end)
	for _, attribute in { "EquippedRevolver", "EquippedKnife" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			showWeapon(weapon)
		end)
	end
	onWeaponAttribute()

	Net.onClient("HitConfirm", function(confirm: Types.HitConfirm)
		local kind: HudController.HitKind = if confirm.killed
			then "kill"
			elseif confirm.headshot then "headshot"
			else "hit"
		HudController.hitMarker(kind)
		SoundController.play(
			if kind == "kill" then "Kill" elseif kind == "headshot" then "Headshot" else "Hit"
		)
	end)
	Net.onClient("ShotFired", function(shooter: Player, origin: Vector3, hitPosition: Vector3)
		if shooter ~= player then
			Effects.tracer(origin, hitPosition)
			Effects.impact(hitPosition)
			SoundController.playAt("Fire", origin)
		end
	end)

	RunService:BindToRenderStep(
		BIND_NAME,
		Enum.RenderPriority.Camera.Value + 2,
		function(dt: number)
			local character = player.Character
			local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
			local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
			viewmodel:update(dt, moving)
		end
	)
end

return WeaponController
