--!strict
-- DebugCommands: Studio-only test harness. Exposes the *running* Services through a BindableFunction
-- at ServerStorage.DebugCommands so MCP execute_luau (Server) can drive duels without a second client.
-- Never created outside Studio (Config.Debug is false there).
--   ServerStorage.DebugCommands:Invoke("startDuel", "1v1", {"NameA"}, {"NameB"}) -> duelId
--   ServerStorage.DebugCommands:Invoke("abort", duelId) -> boolean
--   ServerStorage.DebugCommands:Invoke("kill", "Name") -> boolean
--   ServerStorage.DebugCommands:Invoke("state", "Name") -> PlayerState table
--   ServerStorage.DebugCommands:Invoke("strikes", "Name") -> number of dropped remotes
--   ServerStorage.DebugCommands:Invoke("dummy", "Name", distance?) -> training dummy in front of Name
--   ServerStorage.DebugCommands:Invoke("activeDuels") -> number
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Log = require(Shared.Util.Log)
local Net = require(Shared.Net.Net)
local PlayerState = require(script.Parent.PlayerState)
local DuelService = require(script.Parent.Services.DuelService)
local DataService = require(script.Parent.Services.DataService)
local ProgressionService = require(script.Parent.Services.ProgressionService)
local MonetisationService = require(script.Parent.Services.MonetisationService)
local AntiCheatService = require(script.Parent.Services.AntiCheatService)

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

-- A stationary humanoid target with a Head, 100 HP, removed a second after it dies.
local function spawnDummy(cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "TrainingDummy"
	local function part(name: string, size: Vector3, offset: CFrame, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cframe * offset
		p.Color = color
		p.Anchored = true
		p.Parent = model
		return p
	end
	local root =
		part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(), Color3.fromRGB(200, 60, 60))
	part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0), Color3.fromRGB(240, 200, 60))
	part("Legs", Vector3.new(2, 2, 1), CFrame.new(0, -2, 0), Color3.fromRGB(90, 90, 100))
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = Workspace
	humanoid.Died:Connect(function()
		task.delay(1, function()
			model:Destroy()
		end)
	end)
	return model
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
	strikes = function(name: string)
		return Net.getStrikes(playersNamed({ name })[1])
	end,
	flags = function(name: string)
		return AntiCheatService.getFlags(playersNamed({ name })[1])
	end,
	dummy = function(name: string, distance: number?)
		local player = playersNamed({ name })[1]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return nil
		end
		-- Face the player, standing on the same floor level.
		local ahead = root.CFrame * CFrame.new(0, 0, -(distance or 10))
		local cframe = CFrame.lookAt(ahead.Position, root.Position)
		return spawnDummy(cframe):GetFullName()
	end,
	profile = function(name: string)
		local profile = DataService.getProfile(playersNamed({ name })[1])
		return if profile then table.clone(profile.Data) else nil
	end,
	addXP = function(name: string, amount: number)
		return ProgressionService.addXP(playersNamed({ name })[1], amount)
	end,
	-- Fake a Marketplace receipt (no Robux involved) to exercise ProcessReceipt idempotency.
	receipt = function(name: string, productId: number, purchaseId: string)
		local player = playersNamed({ name })[1]
		return MonetisationService.handleReceipt({
			PlayerId = player.UserId,
			ProductId = productId,
			PurchaseId = purchaseId,
		}).Name
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
