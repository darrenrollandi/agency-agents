--!strict
local Skins = require(game:GetService("ReplicatedStorage").Shared.Config.Skins)
local Definitions = require(game:GetService("ReplicatedStorage").Shared.Net.Definitions)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["ids are unique and resolve"] = function(assertEqual: Assert)
		local seen = {}
		for _, def in Skins.Defs do
			assertEqual(seen[def.id], nil, `duplicate {def.id}`)
			seen[def.id] = true
			assertEqual(Skins.get(def.id), def, `get {def.id}`)
		end
		assertEqual(Skins.get("Nope"), nil, "unknown")
	end,

	["each weapon has exactly one default and it is owned at level 0"] = function(
		assertEqual: Assert
	)
		for _, weapon in { "Revolver", "Knife" } do
			local defaults = 0
			for _, def in Skins.forWeapon(weapon :: any) do
				if Skins.isDefault(def) then
					defaults += 1
				end
			end
			assertEqual(defaults, 1, `{weapon} defaults`)
			local default = Skins.get(Skins.defaultFor(weapon :: any))
			assertEqual(
				default ~= nil and default.weapon == weapon,
				true,
				`{weapon} default resolves`
			)
		end
		local atZero = Skins.unlockedAtLevel(0)
		assertEqual(#atZero, 2, "only defaults at level 0")
	end,

	["level unlocks accumulate"] = function(assertEqual: Assert)
		local at5 = #Skins.unlockedAtLevel(5)
		local at10 = #Skins.unlockedAtLevel(10)
		assertEqual(at5 > 2, true, "some unlocked by 5")
		assertEqual(at10 >= at5, true, "monotonic")
		for _, def in Skins.unlockedAtLevel(10) do
			assertEqual(def.gamePass, nil, `{def.id} game pass skins never unlock by level`)
		end
	end,

	["EquipSkin validator"] = function(assertEqual: Assert)
		local validate = Definitions.EquipSkin.validate :: (...any) -> boolean
		assertEqual(validate("RevolverGold"), true, "ok")
		assertEqual(validate(""), false, "empty")
		assertEqual(validate(string.rep("a", 41)), false, "too long")
		assertEqual(validate(5), false, "number")
		assertEqual(validate("a", "b"), false, "two args")
	end,
}
