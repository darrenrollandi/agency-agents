--!strict
-- Viewmodel: the client-only weapon rig parented to the Camera and re-pivoted every frame. Anchored
-- parts, no physics; recoil kick and idle sway are plain CFrame maths.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local CameraConfig = require(Shared.Config.Camera)
local WeaponModels = require(Shared.WeaponModels)

-- Grip position relative to the camera for each weapon.
local OFFSETS: { [Types.WeaponId]: CFrame } = {
	Revolver = CFrame.new(0.65, -0.55, -1.3) * CFrame.Angles(0, math.rad(-3), 0),
	Knife = CFrame.new(0.6, -0.6, -1.2) * CFrame.Angles(math.rad(-8), math.rad(-15), math.rad(15)),
}

local Viewmodel = {}
Viewmodel.__index = Viewmodel

type Anim = { kind: "reload" | "swing", startedAt: number, duration: number }

export type Viewmodel = typeof(setmetatable(
	{} :: {
		_model: Model?,
		_weapon: Types.WeaponId?,
		_skin: string?,
		_kick: number,
		_time: number,
		_anim: Anim?,
	},
	Viewmodel
))

function Viewmodel.new(): Viewmodel
	return setmetatable(
		{ _model = nil, _weapon = nil, _skin = nil, _kick = 0, _time = 0, _anim = nil },
		Viewmodel
	)
end

-- Procedural one-shot animations layered on the idle pose.
local function animOffset(anim: Anim?): CFrame
	if not anim then
		return CFrame.new()
	end
	local t = math.clamp((os.clock() - anim.startedAt) / anim.duration, 0, 1)
	local wave = math.sin(t * math.pi)
	if anim.kind == "reload" then
		-- Dip down and roll the cylinder side out, then back.
		return CFrame.new(0, -0.45 * wave, 0.1 * wave) * CFrame.Angles(0, 0, math.rad(-55) * wave)
	end
	-- Swing: a quick slash arc from upper-right to lower-left.
	local arc = math.sin(t * math.pi * 0.5)
	return CFrame.new(-0.35 * arc, -0.15 * arc, -0.3 * wave)
		* CFrame.Angles(math.rad(-50) * wave, math.rad(35) * arc, math.rad(20) * wave)
end

-- Dip-and-roll for `seconds` (the reload time).
function Viewmodel.playReload(self: Viewmodel, seconds: number)
	self._anim = { kind = "reload", startedAt = os.clock(), duration = seconds }
end

-- A slash arc for `seconds`.
function Viewmodel.playSwing(self: Viewmodel, seconds: number)
	self._anim = { kind = "swing", startedAt = os.clock(), duration = seconds }
end

-- Show `weapon` in `skin`, or hide everything with nil. Rebuilds only when something changed.
function Viewmodel.setWeapon(self: Viewmodel, weapon: Types.WeaponId?, skin: string?)
	if self._weapon == weapon and self._skin == skin and (self._model ~= nil or weapon == nil) then
		return
	end
	if self._model then
		self._model:Destroy()
		self._model = nil
	end
	self._weapon = weapon
	self._skin = skin
	self._kick = 0
	self._anim = nil
	if weapon then
		local model = WeaponModels.build(weapon, true, skin)
		model.Name = "Viewmodel"
		model.Parent = Workspace.CurrentCamera
		self._model = model
	end
end

-- Push the weapon back (studs); it eases forward again over the next frames.
function Viewmodel.kick(self: Viewmodel, amount: number)
	self._kick = math.min(self._kick + amount, amount * 2)
end

-- World position of the muzzle/tip, for flashes and tracers.
function Viewmodel.muzzlePosition(self: Viewmodel): Vector3?
	local model, weapon = self._model, self._weapon
	if not model or not weapon then
		return nil
	end
	return model:GetPivot():PointToWorldSpace(WeaponModels.MuzzleOffset[weapon])
end

-- Call after the camera has updated for the frame.
function Viewmodel.update(self: Viewmodel, dt: number, moving: boolean)
	local model, weapon = self._model, self._weapon
	if not model or not weapon then
		return
	end
	self._time += dt
	self._kick *= math.max(0, 1 - CameraConfig.ViewmodelRecoveryPerSecond * dt)
	local bob = if moving
		then math.sin(self._time * 9) * 0.03
		else math.sin(self._time * 1.5) * 0.01
	local anim = self._anim
	if anim and os.clock() - anim.startedAt >= anim.duration then
		self._anim = nil
		anim = nil
	end
	local offset = OFFSETS[weapon]
		* CFrame.new(0, bob, self._kick)
		* CFrame.Angles(math.rad(self._kick * 25), 0, 0)
		* animOffset(anim)
	model:PivotTo(Workspace.CurrentCamera.CFrame * offset)
end

function Viewmodel.destroy(self: Viewmodel)
	self:setWeapon(nil)
end

return Viewmodel
