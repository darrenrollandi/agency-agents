--!strict
-- MatchmakingService: turns lobby pads into queues and hands full queues to DuelService. (P1)
-- A pad is any BasePart under Workspace.Lobby named Pad_* with a numeric TeamSize attribute.
-- Standing on a pad queues you; stepping off leaves. Occupancy is one overlap query per pad per tick,
-- because Touched/TouchEnded are unreliable for "is still standing here".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Modes = require(Shared.Config.Modes)
local DuelRules = require(Shared.DuelRules)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local PlayerState = require(script.Parent.Parent.PlayerState)
local DuelService = require(script.Parent.DuelService)
local ProgressionService = require(script.Parent.ProgressionService)

local SCAN_INTERVAL = 0.2
local PAD_HEIGHT = 8

type Pad = {
	name: string,
	part: BasePart,
	label: TextLabel?,
	mode: Types.TeamMode,
	teamSize: number,
	queue: { Player },
}

local MatchmakingService = {}

local pads: { [string]: Pad } = {}

local function needed(pad: Pad): number
	return pad.teamSize * 2
end

-- Push the queue count to everyone in it and onto the pad's floating label.
local function publish(pad: Pad)
	local count = #pad.queue
	if pad.label then
		pad.label.Text = if count > 0 then `{pad.mode}  {count}/{needed(pad)}` else pad.mode
	end
	for _, player in pad.queue do
		local status: Types.QueueStatus = {
			padName = pad.name,
			mode = pad.mode,
			count = count,
			needed = needed(pad),
		}
		Net.fireClient(player, "QueueStatus", status)
	end
end

local function leaveQueue(player: Player, notify: boolean)
	local state = PlayerState.get(player)
	local padName = state.queuePad
	if not padName then
		return
	end
	state.queuePad = nil
	local pad = pads[padName]
	if not pad then
		return
	end
	local index = table.find(pad.queue, player)
	if index then
		table.remove(pad.queue, index)
	end
	if notify then
		Net.fireClient(player, "QueueStatus", nil)
	end
	publish(pad)
end

local function joinQueue(pad: Pad, player: Player)
	local state = PlayerState.get(player)
	if state.queuePad then
		leaveQueue(player, false)
	end
	table.insert(pad.queue, player)
	state.queuePad = pad.name
	Log.debug(`Matchmaking: {player.Name} queued on {pad.name} ({#pad.queue}/{needed(pad)})`)
	publish(pad)
end

local function tryLaunch(pad: Pad)
	local size = needed(pad)
	if #pad.queue < size then
		return
	end
	local players: { Player } = {}
	for _ = 1, size do
		local player = table.remove(pad.queue, 1) :: Player
		PlayerState.get(player).queuePad = nil
		Net.fireClient(player, "QueueStatus", nil)
		table.insert(players, player)
	end
	local teamA, teamB = DuelRules.splitTeams(players, pad.teamSize)
	local duelId = DuelService.startDuel(pad.mode, teamA, teamB)
	if not duelId then
		for _, player in players do
			Net.fireClient(
				player,
				"Notify",
				"No arena is free right now. Step off and on to retry."
			)
		end
	end
	publish(pad)
end

-- Players whose character is standing in the pad's footprint.
local function occupants(pad: Pad): { [Player]: boolean }
	local size = pad.part.Size
	local box = Vector3.new(size.X, PAD_HEIGHT, size.Z)
	local center = pad.part.CFrame * CFrame.new(0, size.Y / 2 + PAD_HEIGHT / 2, 0)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pad.part }
	local found: { [Player]: boolean } = {}
	for _, part in Workspace:GetPartBoundsInBox(center, box, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		local player = if model then Players:GetPlayerFromCharacter(model) else nil
		if player then
			found[player] = true
		end
	end
	return found
end

local function scan(pad: Pad)
	local standing = occupants(pad)
	-- Leave: queued but no longer on the pad.
	for index = #pad.queue, 1, -1 do
		local player = pad.queue[index]
		if not standing[player] then
			leaveQueue(player, true)
		end
	end
	-- Join: on the pad, free, not yet queued here.
	for player in standing do
		local state = PlayerState.get(player)
		-- Nobody queues before their data is loaded: a duel must always be able to award XP.
		if
			state.queuePad ~= pad.name
			and not PlayerState.inDuel(player)
			and ProgressionService.isReady(player)
		then
			joinQueue(pad, player)
		end
	end
	tryLaunch(pad)
end

local function registerPad(part: BasePart)
	if pads[part.Name] then
		return
	end
	local teamSize = part:GetAttribute("TeamSize")
	if typeof(teamSize) ~= "number" then
		Log.warn(`Matchmaking: {part.Name} has no numeric TeamSize attribute; ignored`)
		return
	end
	local mode = Modes.fromTeamSize(teamSize)
	if not mode then
		Log.warn(`Matchmaking: {part.Name} TeamSize {teamSize} matches no enabled mode; ignored`)
		return
	end
	local billboard = part:FindFirstChildWhichIsA("BillboardGui")
	local label = if billboard then billboard:FindFirstChildWhichIsA("TextLabel") else nil

	local pad: Pad = {
		name = part.Name,
		part = part,
		label = label,
		mode = mode,
		teamSize = teamSize,
		queue = {},
	}
	pads[part.Name] = pad
	publish(pad)
	Log.info(`Matchmaking: registered {part.Name} as {mode}`)
end

-- Remove a player from whatever queue they're in.
function MatchmakingService.leaveQueue(player: Player)
	leaveQueue(player, true)
end

function MatchmakingService.start()
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if not lobby then
		Log.warn("Matchmaking: Workspace.Lobby not found; no pads registered")
		return
	end
	local function consider(child: Instance)
		if child:IsA("BasePart") and child.Name:match("^Pad_") then
			registerPad(child)
		end
	end
	for _, child in lobby:GetChildren() do
		consider(child)
	end
	lobby.ChildAdded:Connect(consider)
	Players.PlayerRemoving:Connect(function(player)
		leaveQueue(player, false)
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < SCAN_INTERVAL then
			return
		end
		elapsed = 0
		for _, pad in pads do
			if pad.part.Parent then
				scan(pad)
			end
		end
	end)
end

return MatchmakingService
