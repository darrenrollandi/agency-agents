--!strict
-- Abilities: the fixed ability loadout, two per weapon. Defaults chosen 07/09/2026 to unblock P3;
-- the design session with Mason replaces names, numbers or whole abilities. Server logic lives in
-- Services/AbilityService, client VFX in Controllers/AbilityController; this file is data only.
local Types = require(script.Parent.Parent.Types)

export type AbilityId = "SpeedLoader" | "DeadEye" | "Dash" | "SecondWind"

export type AbilityDef = {
	id: AbilityId,
	name: string,
	description: string,
	weapon: Types.WeaponId,
	-- 1 = Ability1 key (E / L1), 2 = Ability2 key (F / R1).
	slot: number,
	cooldownSeconds: number,
	params: { [string]: number },
}

local Defs: { [AbilityId]: AbilityDef } = {
	SpeedLoader = {
		id = "SpeedLoader",
		name = "Speed Loader",
		description = "Instantly reload the revolver.",
		weapon = "Revolver",
		slot = 1,
		cooldownSeconds = 12,
		params = {},
	},
	DeadEye = {
		id = "DeadEye",
		name = "Dead Eye",
		description = "Your next shot within 4 s deals double damage.",
		weapon = "Revolver",
		slot = 2,
		cooldownSeconds = 15,
		params = { Multiplier = 2, WindowSeconds = 4 },
	},
	Dash = {
		id = "Dash",
		name = "Dash",
		description = "Burst forward.",
		weapon = "Knife",
		slot = 1,
		cooldownSeconds = 6,
		params = { Speed = 70, DurationSeconds = 0.18 },
	},
	SecondWind = {
		id = "SecondWind",
		name = "Second Wind",
		description = "Recover 40 health over 2 s.",
		weapon = "Knife",
		slot = 2,
		cooldownSeconds = 18,
		params = { Heal = 40, DurationSeconds = 2 },
	},
}

local Abilities = {}
Abilities.Defs = Defs
Abilities.Slots = 2

-- Abilities for a weapon, ordered by slot.
function Abilities.forWeapon(weapon: Types.WeaponId): { AbilityDef }
	local list: { AbilityDef } = {}
	for _, def in Defs do
		if def.weapon == weapon then
			table.insert(list, def)
		end
	end
	table.sort(list, function(a, b)
		return a.slot < b.slot
	end)
	return list
end

-- The ability bound to `slot` for `weapon`, or nil.
function Abilities.get(weapon: Types.WeaponId, slot: number): AbilityDef?
	for _, def in Defs do
		if def.weapon == weapon and def.slot == slot then
			return def
		end
	end
	return nil
end

-- Attribute name the server publishes the ready-time under (workspace:GetServerTimeNow() seconds).
function Abilities.cooldownAttribute(id: AbilityId): string
	return `Cooldown_{id}`
end

return Abilities
