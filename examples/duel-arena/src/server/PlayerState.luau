--!strict
-- PlayerState: the server-side table of what each player is doing. The only source of truth for
-- "queued where / in which duel / on which team". Never mirrored to the client except via DuelUpdate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Shared").Types)

export type State = {
	queuePad: string?,
	duelId: number?,
	team: Types.TeamId?,
}

local PlayerState = {}

local states: { [Player]: State } = {}

-- The player's state, created on first access.
function PlayerState.get(player: Player): State
	local state = states[player]
	if not state then
		state = { queuePad = nil, duelId = nil, team = nil }
		states[player] = state
	end
	return state
end

function PlayerState.inDuel(player: Player): boolean
	local state = states[player]
	return state ~= nil and state.duelId ~= nil
end

-- Forget a player entirely. Connect last on PlayerRemoving so Services can read the state first.
function PlayerState.clear(player: Player)
	states[player] = nil
end

return PlayerState
