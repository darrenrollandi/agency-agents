--!strict
-- DuelRules: the pure rules behind DuelService. No engine calls, so tests cover every branch.
local Types = require(script.Parent.Types)

type DuelState = Types.DuelState
type TeamId = Types.TeamId

-- Round result: a team, or "Draw" when both teams are wiped in the same instant.
export type Outcome = TeamId | "Draw"

local DuelRules = {}

local TRANSITIONS: { [DuelState]: { [DuelState]: boolean } } = {
	Waiting = { Countdown = true, Cleanup = true },
	Countdown = { Live = true, DuelOver = true, Cleanup = true },
	Live = { RoundOver = true, Cleanup = true },
	RoundOver = { Countdown = true, DuelOver = true, Cleanup = true },
	DuelOver = { Cleanup = true },
	Cleanup = {},
}

function DuelRules.canTransition(from: DuelState, to: DuelState): boolean
	local allowed = TRANSITIONS[from]
	return allowed ~= nil and allowed[to] == true
end

-- Outcome once a team is fully eliminated; nil while both teams still have someone alive.
function DuelRules.roundOutcome(aliveA: number, aliveB: number): Outcome?
	if aliveA <= 0 and aliveB <= 0 then
		return "Draw"
	elseif aliveB <= 0 then
		return "A"
	elseif aliveA <= 0 then
		return "B"
	end
	return nil
end

-- When the round timer expires: more survivors wins; equal survivors → nil, meaning sudden death.
function DuelRules.timeoutOutcome(aliveA: number, aliveB: number): TeamId?
	if aliveA > aliveB then
		return "A"
	elseif aliveB > aliveA then
		return "B"
	end
	return nil
end

function DuelRules.isDuelOver(scoreA: number, scoreB: number, pointsToWin: number): boolean
	return scoreA >= pointsToWin or scoreB >= pointsToWin
end

-- Leader on points; nil when tied (only reachable via forfeit).
function DuelRules.duelWinner(scoreA: number, scoreB: number): TeamId?
	if scoreA > scoreB then
		return "A"
	elseif scoreB > scoreA then
		return "B"
	end
	return nil
end

-- Deal a queue into two teams, alternating, so friends who queued together are split fairly.
function DuelRules.splitTeams<T>(players: { T }, teamSize: number): ({ T }, { T })
	local teamA: { T } = {}
	local teamB: { T } = {}
	for index, player in players do
		if #teamA >= teamSize and #teamB >= teamSize then
			break
		end
		if (index % 2 == 1 and #teamA < teamSize) or #teamB >= teamSize then
			table.insert(teamA, player)
		else
			table.insert(teamB, player)
		end
	end
	return teamA, teamB
end

return DuelRules
