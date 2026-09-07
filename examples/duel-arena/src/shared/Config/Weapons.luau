--!strict
-- Weapons: combat tunables. Defaults set 07/09/2026 (GAME_DESIGN.md → Weapons); D and Mason to tune.
-- Player health is 100: three body shots or a headshot plus a body shot; the knife is a two-hit kill.
local Weapons = {
	Revolver = {
		Cylinder = 6,
		Damage = 35,
		HeadshotMultiplier = 2,
		-- Seconds between shots (semi-automatic).
		FireInterval = 0.4,
		ReloadSeconds = 1.6,
		MaxRange = 400,
		-- Server validation: how far the claimed shot origin may sit from the shooter's head, and how
		-- far the server ray may pass from a claimed victim's root and still count (lag tolerance).
		OriginTolerance = 8,
		HitTolerance = 3,
	},
	Knife = {
		Damage = 50,
		Range = 6,
		-- Box in front of the attacker's root part; depth is Range.
		HitboxSize = Vector3.new(4.5, 5, 6),
		SwingInterval = 0.45,
	},
}

return Weapons
