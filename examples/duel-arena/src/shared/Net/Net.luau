--!strict
-- Net: creates and caches every remote from Definitions under Shared.Net.Remotes (server) and wraps
-- them so a client→server payload is rate-limited and validated before any handler sees it. (P1)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local netFolder = script.Parent :: Instance
local Definitions = require(script.Parent.Definitions)
local Log = require(script.Parent.Parent.Util.Log)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)

local REMOTES_FOLDER = "Remotes"
local IS_SERVER = RunService:IsServer()

local Net = {}

local remotes: { [string]: RemoteEvent } = {}
local limiters: { [string]: RateLimiter.RateLimiter } = {}
local strikes: { [Player]: number } = {}
local warned: { [Player]: boolean } = {}

local function definition(name: string): Definitions.Definition
	local def = Definitions[name]
	if not def then
		Log.error(`Net: unknown remote "{name}"`, 2)
	end
	return def
end

local function strike(player: Player, name: string, reason: string)
	strikes[player] = (strikes[player] or 0) + 1
	if not warned[player] then
		warned[player] = true
		Log.warn(`Net: dropped "{name}" from {player.Name} ({reason}); further drops are silent`)
	end
end

local function getRemote(name: string): RemoteEvent
	local cached = remotes[name]
	if cached then
		return cached
	end
	definition(name)
	local folder = netFolder:WaitForChild(REMOTES_FOLDER)
	local remote = folder:WaitForChild(name) :: RemoteEvent
	remotes[name] = remote
	return remote
end

-- Server only. Creates every remote in Definitions. Call once, before any Service starts.
function Net.init()
	if not IS_SERVER then
		Log.error("Net.init is server-only")
	end
	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER
	for name, def in Definitions do
		local remote: Instance = if def.kind == "Unreliable"
			then Instance.new("UnreliableRemoteEvent")
			else Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remotes[name] = remote :: any
		if def.direction == "ClientToServer" then
			if not def.ratePerSecond or not def.validate then
				Log.error(
					`Net: "{name}" is ClientToServer and must define ratePerSecond and validate`
				)
			end
			limiters[name] = RateLimiter.new(def.ratePerSecond :: number)
		end
	end
	folder.Parent = netFolder
	Players.PlayerRemoving:Connect(function(player)
		strikes[player] = nil
		warned[player] = nil
		for _, limiter in limiters do
			limiter:forget(player)
		end
	end)
end

-- Server: handle a client→server remote. Only payloads passing the rate limit and validator reach `handler`.
function Net.onServer(name: string, handler: (Player, ...any) -> ()): RBXScriptConnection
	local def = definition(name)
	if def.direction ~= "ClientToServer" then
		Log.error(`Net.onServer: "{name}" is not ClientToServer`)
	end
	local limiter = limiters[name]
	local validate = def.validate :: (...any) -> boolean
	return getRemote(name).OnServerEvent:Connect(function(player: Player, ...: any)
		if not limiter:allow(player, os.clock()) then
			strike(player, name, "rate limit")
			return
		end
		if not validate(...) then
			strike(player, name, "invalid payload")
			return
		end
		handler(player, ...)
	end)
end

-- Server: send to one player.
function Net.fireClient(player: Player, name: string, ...: any)
	if definition(name).direction ~= "ServerToClient" then
		Log.error(`Net.fireClient: "{name}" is not ServerToClient`)
	end
	getRemote(name):FireClient(player, ...)
end

-- Server: send to everyone.
function Net.fireAllClients(name: string, ...: any)
	if definition(name).direction ~= "ServerToClient" then
		Log.error(`Net.fireAllClients: "{name}" is not ServerToClient`)
	end
	getRemote(name):FireAllClients(...)
end

-- Server: how many bad payloads this player has sent (for kicking repeat offenders later).
function Net.getStrikes(player: Player): number
	return strikes[player] or 0
end

-- Client: handle a server→client remote.
function Net.onClient(name: string, handler: (...any) -> ()): RBXScriptConnection
	return getRemote(name).OnClientEvent:Connect(handler)
end

-- Client: send to the server.
function Net.fireServer(name: string, ...: any)
	getRemote(name):FireServer(...)
end

return Net
