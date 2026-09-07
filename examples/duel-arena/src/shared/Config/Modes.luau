--!strict
-- Modes: team-size definitions. A lobby pad selects its mode via its `TeamSize` attribute.
local Types = require(script.Parent.Parent.Types)

export type ModeDef = {
	TeamSize: number,
	Enabled: boolean,
}

local Defs: { [Types.TeamMode]: ModeDef } = {
	["1v1"] = { TeamSize = 1, Enabled = true },
	["2v2"] = { TeamSize = 2, Enabled = true },
	["3v3"] = { TeamSize = 3, Enabled = true },
	["4v4"] = { TeamSize = 4, Enabled = true },
}

local Modes = {}
Modes.Defs = Defs

-- Mode for a pad's TeamSize attribute, or nil if no enabled mode matches.
function Modes.fromTeamSize(teamSize: number): Types.TeamMode?
	for mode, def in Defs do
		if def.TeamSize == teamSize and def.Enabled then
			return mode
		end
	end
	return nil
end

return Modes
