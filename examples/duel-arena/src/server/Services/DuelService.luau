--!strict
-- DuelService: the duel state machine. Waiting → Countdown → Live → RoundOver → (Countdown | DuelOver)
-- → Cleanup. Every transition is checked against DuelRules and logged. No gameplay outside Live. (P1)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Rounds = require(Shared.Config.Rounds)
local DuelRules = require(Shared.DuelRules)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local Trove = require(Shared.Util.Trove)
local PlayerState = require(script.Parent.Parent.PlayerState)
local Arena = require(script.Parent.Parent.Arena)
local CharacterService = require(script.Parent.CharacterService)
local CombatService = require(script.Parent.CombatService)

type TeamId = Types.TeamId
type DuelState = Types.DuelState

type Duel = {
	id: number,
	mode: Types.TeamMode,
	state: DuelState,
	round: number,
	teams: { [TeamId]: { Player } },
	score: { [TeamId]: number },
	alive: { [Player]: boolean },
	arena: Arena.ArenaInstance,
	trove: Trove.Trove, -- lives for the whole duel
	roundTrove: Trove.Trove, -- reset every round: death hooks and timers
	suddenDeath: boolean,
	forfeit: boolean,
	countdownEndsAt: number?,
	roundEndsAt: number?,
	roundWinner: TeamId?,
	duelWinner: TeamId?,
}

local TEAMS: { TeamId } = { "A", "B" }

local DuelService = {}

local duels: { [number]: Duel } = {}
local nextId = 1
local handlers: { [DuelState]: (Duel) -> () } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function eachPlayer(duel: Duel, fn: (Player, TeamId) -> ())
	for _, team in TEAMS do
		for _, player in duel.teams[team] do
			fn(player, team)
		end
	end
end

local function aliveCount(duel: Duel, team: TeamId): number
	local count = 0
	for _, player in duel.teams[team] do
		if duel.alive[player] then
			count += 1
		end
	end
	return count
end

local function names(players: { Player }): string
	local list = {}
	for _, player in players do
		table.insert(list, player.Name)
	end
	return table.concat(list, ", ")
end

local function teamEmpty(duel: Duel, team: TeamId): boolean
	return #duel.teams[team] == 0
end

local function broadcast(duel: Duel)
	local aliveA, aliveB = aliveCount(duel, "A"), aliveCount(duel, "B")
	eachPlayer(duel, function(player, team)
		local update: Types.DuelUpdate = {
			duelId = duel.id,
			state = duel.state,
			mode = duel.mode,
			round = duel.round,
			team = team,
			scoreA = duel.score.A,
			scoreB = duel.score.B,
			aliveA = aliveA,
			aliveB = aliveB,
			suddenDeath = duel.suddenDeath,
			forfeit = duel.forfeit,
			countdownEndsAt = duel.countdownEndsAt,
			roundEndsAt = duel.roundEndsAt,
			roundWinner = duel.roundWinner,
			duelWinner = duel.duelWinner,
		}
		Net.fireClient(player, "DuelUpdate", update)
	end)
end

local function transition(duel: Duel, to: DuelState)
	if not DuelRules.canTransition(duel.state, to) then
		Log.error(`[Duel {duel.id}] illegal transition {duel.state} -> {to}`)
	end
	Log.info(`[Duel {duel.id}] {duel.state} -> {to}`)
	duel.state = to
	handlers[to](duel)
end

-- Run fn after `seconds` unless the round trove is cleaned first (round ended) or the duel is gone.
local function scheduleAfter(duel: Duel, seconds: number, fn: () -> ())
	local cancelled = false
	duel.roundTrove:add(function()
		cancelled = true
	end)
	task.delay(seconds, function()
		if not cancelled and duels[duel.id] == duel then
			fn()
		end
	end)
end

local function endRound(duel: Duel, outcome: DuelRules.Outcome)
	if duel.state ~= "Live" then
		return
	end
	duel.roundTrove:clean()
	if outcome == "A" or outcome == "B" then
		duel.score[outcome] += 1
		duel.roundWinner = outcome
	else
		duel.roundWinner = nil
	end
	transition(duel, "RoundOver")
end

local function onDeath(duel: Duel, player: Player, character: Model?)
	if duel.state ~= "Live" or not duel.alive[player] then
		return
	end
	duel.alive[player] = false
	CombatService.disarm(player)
	if character then
		-- Readable, not gory: the body lies for a moment, then goes.
		task.delay(Rounds.CorpseSeconds, function()
			if character.Parent then
				character:Destroy()
			end
		end)
	end
	Log.debug(`[Duel {duel.id}] {player.Name} eliminated`)
	local outcome = DuelRules.roundOutcome(aliveCount(duel, "A"), aliveCount(duel, "B"))
	if outcome then
		endRound(duel, outcome)
	else
		broadcast(duel)
	end
end

local function spawnCFrame(duel: Duel, team: TeamId, index: number): CFrame
	local spawns = duel.arena.spawns[team]
	local part = spawns[((index - 1) % #spawns) + 1]
	return part.CFrame + Vector3.new(0, 3, 0)
end

local function disarmAll(duel: Duel)
	eachPlayer(duel, function(player)
		CombatService.disarm(player)
	end)
end

handlers.Countdown = function(duel)
	if teamEmpty(duel, "A") or teamEmpty(duel, "B") then
		duel.forfeit = true
		transition(duel, "DuelOver")
		return
	end
	duel.round += 1
	duel.roundTrove:clean()
	duel.alive = {}
	duel.suddenDeath = false
	duel.roundWinner = nil
	duel.roundEndsAt = nil
	for _, team in TEAMS do
		for index, player in duel.teams[team] do
			local character = CharacterService.spawnAt(player, spawnCFrame(duel, team, index))
			if character then
				duel.alive[player] = true
				CharacterService.setFrozen(character, true)
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					duel.roundTrove:connect(humanoid.Died, function()
						onDeath(duel, player, character)
					end)
				end
			else
				duel.alive[player] = false
			end
		end
	end
	duel.countdownEndsAt = now() + Rounds.CountdownSeconds
	broadcast(duel)
	scheduleAfter(duel, Rounds.CountdownSeconds, function()
		transition(duel, "Live")
	end)
end

handlers.Live = function(duel)
	duel.countdownEndsAt = nil
	eachPlayer(duel, function(player)
		local character = player.Character
		if character and duel.alive[player] then
			CharacterService.setFrozen(character, false)
			CombatService.arm(player)
		end
	end)
	duel.roundEndsAt = now() + Rounds.RoundTimeSeconds
	broadcast(duel)
	scheduleAfter(duel, Rounds.RoundTimeSeconds, function()
		local outcome = DuelRules.timeoutOutcome(aliveCount(duel, "A"), aliveCount(duel, "B"))
		if outcome then
			endRound(duel, outcome)
		else
			duel.suddenDeath = true
			duel.roundEndsAt = nil
			Log.info(`[Duel {duel.id}] round {duel.round}: sudden death`)
			broadcast(duel)
		end
	end)
	-- Someone may have died or left during the countdown.
	local outcome = DuelRules.roundOutcome(aliveCount(duel, "A"), aliveCount(duel, "B"))
	if outcome then
		endRound(duel, outcome)
	end
end

handlers.RoundOver = function(duel)
	duel.roundEndsAt = nil
	disarmAll(duel)
	Log.info(
		`[Duel {duel.id}] round {duel.round}: {duel.roundWinner or "draw"} ({duel.score.A}-{duel.score.B})`
	)
	broadcast(duel)
	scheduleAfter(duel, Rounds.RoundOverSeconds, function()
		local over = DuelRules.isDuelOver(duel.score.A, duel.score.B, Rounds.PointsToWin)
		if over or teamEmpty(duel, "A") or teamEmpty(duel, "B") then
			transition(duel, "DuelOver")
		else
			transition(duel, "Countdown")
		end
	end)
end

handlers.DuelOver = function(duel)
	duel.roundTrove:clean()
	duel.countdownEndsAt = nil
	duel.roundEndsAt = nil
	disarmAll(duel)
	if teamEmpty(duel, "A") ~= teamEmpty(duel, "B") then
		duel.forfeit = true
		duel.duelWinner = if teamEmpty(duel, "A") then "B" else "A"
	else
		duel.duelWinner = DuelRules.duelWinner(duel.score.A, duel.score.B)
	end
	local suffix = if duel.forfeit then " (forfeit)" else ""
	Log.info(
		`[Duel {duel.id}] over: {duel.duelWinner or "no winner"} {duel.score.A}-{duel.score.B}{suffix}`
	)
	broadcast(duel)
	scheduleAfter(duel, Rounds.DuelOverSeconds, function()
		transition(duel, "Cleanup")
	end)
end

handlers.Cleanup = function(duel)
	duel.roundTrove:clean()
	duel.trove:clean()
	disarmAll(duel) -- an abort can arrive straight from Live
	broadcast(duel)
	eachPlayer(duel, function(player)
		local state = PlayerState.get(player)
		state.duelId = nil
		state.team = nil
		CharacterService.spawnInLobby(player)
	end)
	duel.arena.release()
	duels[duel.id] = nil
	Log.info(`[Duel {duel.id}] cleaned up`)
end

-- Start a duel between two teams. Returns the duel id, or nil when no arena is free.
function DuelService.startDuel(mode: Types.TeamMode, teamA: { Player }, teamB: { Player }): number?
	local arena = Arena.acquire()
	if not arena then
		return nil
	end
	local id = nextId
	nextId += 1
	local duel: Duel = {
		id = id,
		mode = mode,
		state = "Waiting",
		round = 0,
		teams = { A = table.clone(teamA), B = table.clone(teamB) },
		score = { A = 0, B = 0 },
		alive = {},
		arena = arena,
		trove = Trove.new(),
		roundTrove = Trove.new(),
		suddenDeath = false,
		forfeit = false,
	}
	duels[id] = duel
	eachPlayer(duel, function(player, team)
		local state = PlayerState.get(player)
		state.duelId = id
		state.team = team
	end)
	Log.info(`[Duel {id}] {mode}: A [{names(teamA)}] vs B [{names(teamB)}] in {arena.model.Name}`)
	transition(duel, "Countdown")
	return id
end

-- Drops a leaving player from their duel and resolves the round if that decides it.
-- Must run before PlayerState.clear.
function DuelService.handlePlayerRemoving(player: Player)
	local duelId = PlayerState.get(player).duelId
	local duel = if duelId then duels[duelId] else nil
	if not duel then
		return
	end
	for _, team in TEAMS do
		local index = table.find(duel.teams[team], player)
		if index then
			table.remove(duel.teams[team], index)
		end
	end
	Log.info(`[Duel {duel.id}] {player.Name} left during {duel.state}`)
	if duel.state == "Live" then
		onDeath(duel, player)
	elseif duel.state == "Countdown" and (teamEmpty(duel, "A") or teamEmpty(duel, "B")) then
		duel.forfeit = true
		duel.roundTrove:clean()
		transition(duel, "DuelOver")
	end
	if
		duels[duel.id] == duel
		and duel.state ~= "Cleanup"
		and teamEmpty(duel, "A")
		and teamEmpty(duel, "B")
	then
		duel.roundTrove:clean()
		transition(duel, "Cleanup")
	end
end

-- Tear a duel down immediately, sending everyone back to the lobby. No points awarded.
function DuelService.abort(duelId: number): boolean
	local duel = duels[duelId]
	if not duel or duel.state == "Cleanup" then
		return false
	end
	Log.info(`[Duel {duel.id}] aborted during {duel.state}`)
	duel.roundTrove:clean()
	transition(duel, "Cleanup")
	return true
end

-- Number of duels in progress (diagnostics).
function DuelService.activeCount(): number
	local count = 0
	for _ in duels do
		count += 1
	end
	return count
end

function DuelService.start()
	Players.PlayerRemoving:Connect(DuelService.handlePlayerRemoving)
end

return DuelService
