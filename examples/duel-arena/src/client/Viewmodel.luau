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

export type Viewmodel = typeof(setmetatable(
	{} :: { _model: Model?, _weapon: Types.WeaponId?, _kick: number, _time: number },
	Viewmodel
))

function Viewmodel.new(): Viewmodel
	return setmetatable({ _model = nil, _weapon = nil, _kick = 0, _time = 0 }, Viewmodel)
end

-- Show `weapon`, or hide everything with nil.
function Viewmodel.setWeapon(self: Viewmodel, weapon: Types.WeaponId?)
	if self._weapon == weapon and self._model then
		return
	end
	if self._model then
		self._model:Destroy()
		self._model = nil
	end
	self._weapon = weapon
	self._kick = 0
	if weapon then
		local model = WeaponModels.build(weapon, true)
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
	local offset = OFFSETS[weapon]
		* CFrame.new(0, bob, self._kick)
		* CFrame.Angles(math.rad(self._kick * 25), 0, 0)
	model:PivotTo(Workspace.CurrentCamera.CFrame * offset)
end

function Viewmodel.destroy(self: Viewmodel)
	self:setWeapon(nil)
end

return Viewmodel
