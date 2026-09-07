--!strict
local Abilities = require(game:GetService("ReplicatedStorage").Shared.Config.Abilities)
local Definitions = require(game:GetService("ReplicatedStorage").Shared.Net.Definitions)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["each weapon has one ability per slot"] = function(assertEqual: Assert)
		for _, weapon in { "Revolver", "Knife" } do
			local list = Abilities.forWeapon(weapon :: any)
			assertEqual(#list, Abilities.Slots, `{weapon} count`)
			for slot = 1, Abilities.Slots do
				local def = Abilities.get(weapon :: any, slot)
				assertEqual(def ~= nil, true, `{weapon} slot {slot} exists`)
				assertEqual((def :: any).slot, slot, `{weapon} slot {slot} index`)
				assertEqual((def :: any).weapon, weapon, `{weapon} slot {slot} weapon`)
			end
		end
	end,

	["every ability has a positive cooldown and matching id"] = function(assertEqual: Assert)
		for id, def in Abilities.Defs do
			assertEqual(def.id, id, `{id} id`)
			assertEqual(def.cooldownSeconds > 0, true, `{id} cooldown`)
			assertEqual(typeof(def.name), "string", `{id} name`)
		end
	end,

	["UseAbility accepts slots 1 and 2 only"] = function(assertEqual: Assert)
		local validate = Definitions.UseAbility.validate :: (...any) -> boolean
		assertEqual(validate(1), true, "1")
		assertEqual(validate(2), true, "2")
		assertEqual(validate(3), false, "3")
		assertEqual(validate("1"), false, "string")
		assertEqual(validate(), false, "missing")
		assertEqual(validate(1, 2), false, "two args")
	end,
}
