--!strict
-- Definitions: every remote in the game, by name. The server creates them from this table at boot.
-- ClientToServer remotes MUST set `ratePerSecond` and a pure `validate` so tests can cover it.
-- Validators only check shape; meaning (alive, ammo, range) is checked by the Service that handles it.
local Weapons = require(script.Parent.Parent.Config.Weapons)
local CameraConfig = require(script.Parent.Parent.Config.Camera)

export type Direction = "ClientToServer" | "ServerToClient"
export type Kind = "Event" | "Unreliable"

export type Definition = {
	kind: Kind,
	direction: Direction,
	ratePerSecond: number?,
	-- How many calls may land at once before the rate applies (default: one second's worth).
	burst: number?,
	validate: ((...any) -> boolean)?,
}

local MAX_COORDINATE = 1e6

local function isFiniteVector(value: any): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end
	local v = value :: Vector3
	-- NaN fails its own equality; huge values are never a real position.
	return v.X == v.X
		and v.Y == v.Y
		and v.Z == v.Z
		and math.abs(v.X) < MAX_COORDINATE
		and math.abs(v.Y) < MAX_COORDINATE
		and math.abs(v.Z) < MAX_COORDINATE
end

local function isUnitVector(value: any): boolean
	if not isFiniteVector(value) then
		return false
	end
	local magnitude = (value :: Vector3).Magnitude
	return magnitude > 0.98 and magnitude < 1.02
end

-- Fire(origin: Vector3, direction: unit Vector3, hitPart: Instance?, timestamp: number)
local function validateFire(...: any): boolean
	if select("#", ...) > 4 then
		return false
	end
	local origin, direction, hitPart, timestamp = ...
	return isFiniteVector(origin)
		and isUnitVector(direction)
		and (hitPart == nil or typeof(hitPart) == "Instance")
		and typeof(timestamp) == "number"
end

local function validateNoPayload(...: any): boolean
	return select("#", ...) == 0
end

local function validateEquip(...: any): boolean
	if select("#", ...) ~= 1 then
		return false
	end
	local weapon = ...
	return weapon == "Revolver" or weapon == "Knife"
end

-- EquipSkin(skinId: string)
local function validateEquipSkin(...: any): boolean
	if select("#", ...) ~= 1 then
		return false
	end
	local skinId = ...
	return typeof(skinId) == "string" and #skinId > 0 and #skinId <= 40
end

-- SaveSettings(sensitivity: number, fieldOfView: number) within the Config/Camera ranges.
local function validateSaveSettings(...: any): boolean
	if select("#", ...) ~= 2 then
		return false
	end
	local sensitivity, fov = ...
	return typeof(sensitivity) == "number"
		and sensitivity == sensitivity
		and sensitivity >= CameraConfig.SensitivityMin
		and sensitivity <= CameraConfig.SensitivityMax
		and typeof(fov) == "number"
		and fov == fov
		and fov >= CameraConfig.FieldOfViewMin
		and fov <= CameraConfig.FieldOfViewMax
end

-- RequestPurchase(kind: "GamePass" | "Product", key: string). The server owns the ids and prompts.
local function validateRequestPurchase(...: any): boolean
	if select("#", ...) ~= 2 then
		return false
	end
	local kind, key = ...
	return (kind == "GamePass" or kind == "Product")
		and typeof(key) == "string"
		and #key > 0
		and #key <= 40
end

-- UseAbility(slot: 1 | 2)
local function validateUseAbility(...: any): boolean
	if select("#", ...) ~= 1 then
		return false
	end
	local slot = ...
	return slot == 1 or slot == 2
end

local Definitions: { [string]: Definition } = {
	-- Lobby: Types.QueueStatus, or nil when the player leaves a queue.
	QueueStatus = { kind = "Event", direction = "ServerToClient" },
	-- Duel flow: Types.DuelUpdate on every state change.
	DuelUpdate = { kind = "Event", direction = "ServerToClient" },
	-- One-line HUD message (string).
	Notify = { kind = "Event", direction = "ServerToClient" },

	-- Combat, client → server. Rate limits sit 25% above the weapon's own cadence.
	Fire = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 1.25 / Weapons.Revolver.FireInterval,
		validate = validateFire,
	},
	Reload = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 2,
		validate = validateNoPayload,
	},
	Swing = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 1.25 / Weapons.Knife.SwingInterval,
		validate = validateNoPayload,
	},
	Equip = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 5,
		validate = validateEquip,
	},

	UseAbility = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 4,
		validate = validateUseAbility,
	},

	-- Progression
	EquipSkin = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 3,
		validate = validateEquipSkin,
	},
	SaveSettings = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 2,
		validate = validateSaveSettings,
	},
	RequestPurchase = {
		kind = "Event",
		direction = "ClientToServer",
		ratePerSecond = 1,
		burst = 3,
		validate = validateRequestPurchase,
	},
	-- ProgressionSnapshot(Types.ProgressionSnapshot) on load and every change.
	ProgressionSnapshot = { kind = "Event", direction = "ServerToClient" },
	-- DuelReward(Types.DuelReward) after a duel.
	DuelReward = { kind = "Event", direction = "ServerToClient" },

	-- Combat, server → client.
	-- HitConfirm(Types.HitConfirm) to the attacker after an accepted hit.
	HitConfirm = { kind = "Event", direction = "ServerToClient" },
	-- AbilityUsed(user: Player, abilityId: string): every client plays the VFX; the owner applies
	-- client-side movement (Dash). Reliable because the owner depends on it.
	AbilityUsed = { kind = "Event", direction = "ServerToClient" },
	-- ShotFired(shooter: Player, origin: Vector3, hitPosition: Vector3): cosmetic tracers for others.
	ShotFired = { kind = "Unreliable", direction = "ServerToClient" },
}

return Definitions
