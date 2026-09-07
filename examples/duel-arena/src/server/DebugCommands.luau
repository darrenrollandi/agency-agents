--!strict
-- DebugCommands: Studio-only test harness. Exposes the *running* Services through a BindableFunction
-- at ServerStorage.DebugCommands so MCP execute_luau (Server) can drive duels without a second client.
-- Never created outside Studio (Config.Debug is false there).
--   ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"NameA"}, {"NameB"}) -> duelId
--   ServerStorage.DebugCommands:Invoke("abort", duelId) -> boolean
--   ServerStorage.DebugCommands:Invoke("kill", "Name") -> boolean
--   ServerStorage.DebugCommands:Invoke("state", "Name") -> PlayerState table
--   ServerStorage.DebugCommands:Invoke("activeDuels") -> number
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Log = require(Shared.Util.Log)
local PlayerState = require(script.Parent.PlayerState)
local DuelService = require(script.Parent.Services.DuelService)

local DebugCommands = {}

local function playersNamed(names: { string }): { Player }
	local result = {}
	for _, name in names do
		local player = Players:FindFirstChild(name)
		if player and player:IsA("Player") then
			table.insert(result, player)
		else
			error(`DebugCommands: no player named {name}`)
		end
	end
	return result
end

local commands: { [string]: (...any) -> any } = {
	startDuel = function(mode: string, teamA: { string }, teamB: { string })
		return DuelService.startDuel(mode :: any, playersNamed(teamA), playersNamed(teamB))
	end,
	abort = function(duelId: number)
		return DuelService.abort(duelId)
	end,
	kill = function(name: string)
		local player = playersNamed({ name })[1]
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return false
		end
		humanoid.Health = 0
		return true
	end,
	state = function(name: string)
		return table.clone(PlayerState.get(playersNamed({ name })[1]))
	end,
	activeDuels = function()
		return DuelService.activeCount()
	end,
}

function DebugCommands.start()
	if not Config.Debug then
		return
	end
	local bindable = Instance.new("BindableFunction")
	bindable.Name = "DebugCommands"
	bindable.OnInvoke = function(command: string, ...: any)
		local handler = commands[command]
		if not handler then
			error(`DebugCommands: unknown command "{command}"`)
		end
		return handler(...)
	end
	bindable.Parent = ServerStorage
	Log.info("DebugCommands available at ServerStorage.DebugCommands (Studio only)")
end

return DebugCommands
