--!strict
local Definitions = require(game:GetService("ReplicatedStorage").Shared.Net.Definitions)

type Assert = (actual: any, expected: any, label: string?) -> ()
type Validator = (...any) -> boolean

local fire = Definitions.Fire.validate :: Validator
local reload = Definitions.Reload.validate :: Validator
local equip = Definitions.Equip.validate :: Validator

local origin = Vector3.new(1000, 5, 1000)
local forward = Vector3.new(0, 0, -1)

return {
	["every client->server remote declares a rate limit and a validator"] = function(
		assertEqual: Assert
	)
		for name, def in Definitions do
			if def.direction == "ClientToServer" then
				assertEqual(typeof(def.ratePerSecond), "number", `{name}.ratePerSecond`)
				assertEqual(typeof(def.validate), "function", `{name}.validate`)
			end
		end
	end,

	["Fire accepts a well-formed shot"] = function(assertEqual: Assert)
		assertEqual(fire(origin, forward, nil, 12.5), true, "no hit part")
		assertEqual(fire(origin, forward, Instance.new("Part"), 12.5), true, "with hit part")
		assertEqual(fire(origin, Vector3.new(0.6, 0, -0.8), nil, 0), true, "diagonal unit")
	end,

	["Fire rejects malformed shots"] = function(assertEqual: Assert)
		assertEqual(fire(origin, Vector3.new(0, 0, -5), nil, 1), false, "non-unit direction")
		assertEqual(fire(origin, Vector3.zero, nil, 1), false, "zero direction")
		assertEqual(fire(Vector3.new(0 / 0, 0, 0), forward, nil, 1), false, "NaN origin")
		assertEqual(fire(Vector3.new(1e9, 0, 0), forward, nil, 1), false, "absurd origin")
		assertEqual(fire("origin", forward, nil, 1), false, "string origin")
		assertEqual(fire(origin, forward, "Head", 1), false, "string hit part")
		assertEqual(fire(origin, forward, nil, "now"), false, "string timestamp")
		assertEqual(fire(origin, forward, nil), false, "missing timestamp")
		assertEqual(fire(origin, forward, nil, 1, "extra"), false, "extra argument")
	end,

	["Reload and Swing take no payload"] = function(assertEqual: Assert)
		assertEqual(reload(), true, "empty")
		assertEqual(reload(1), false, "with payload")
		assertEqual((Definitions.Swing.validate :: Validator)(), true, "swing empty")
	end,

	["SaveSettings enforces the Camera ranges"] = function(assertEqual: Assert)
		local validate = Definitions.SaveSettings.validate :: Validator
		assertEqual(validate(1, 80), true, "defaults")
		assertEqual(validate(0.2, 60), true, "minimums")
		assertEqual(validate(3, 100), true, "maximums")
		assertEqual(validate(0.1, 80), false, "sensitivity too low")
		assertEqual(validate(1, 120), false, "fov too high")
		assertEqual(validate(0 / 0, 80), false, "NaN")
		assertEqual(validate("1", 80), false, "string")
		assertEqual(validate(1), false, "missing fov")
	end,

	["Equip accepts only known weapons"] = function(assertEqual: Assert)
		assertEqual(equip("Revolver"), true, "Revolver")
		assertEqual(equip("Knife"), true, "Knife")
		assertEqual(equip("Rocket"), false, "unknown")
		assertEqual(equip(), false, "missing")
		assertEqual(equip("Knife", "Knife"), false, "two args")
	end,
}
