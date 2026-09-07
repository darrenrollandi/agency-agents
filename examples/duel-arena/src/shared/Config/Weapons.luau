--!strict
-- Weapons: combat tunables. P1 ships only the Tag placeholder; Revolver and Knife land in P2.
local Weapons = {
	Tag = {
		Damage = 100,
		-- The hitbox is a box this deep in front of the attacker's root part.
		Range = 7,
		HitboxSize = Vector3.new(6, 6, 7),
		CooldownSeconds = 0.4,
	},
}

return Weapons
