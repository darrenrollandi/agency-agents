--!strict
local Modes = require(game:GetService("ReplicatedStorage").Shared.Config.Modes)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["fromTeamSize maps pad attributes to modes"] = function(assertEqual: Assert)
		assertEqual(Modes.fromTeamSize(1), "1v1", "1")
		assertEqual(Modes.fromTeamSize(2), "2v2", "2")
		assertEqual(Modes.fromTeamSize(4), "4v4", "4")
		assertEqual(Modes.fromTeamSize(7), nil, "7")
	end,
}
