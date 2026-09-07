--!strict
-- CombatService: server-side damage. P1 ships the "Tag" placeholder: a Tool whose click eliminates the
-- enemy in front of you (server hitbox, no client code). Revolver and knife replace it in P2.
-- Friendly fire is off.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Config.Weapons)
local Log = require(Shared.Util.Log)
local PlayerState = require(script.Parent.Parent.PlayerState)

local TOOL_NAME = "Tag"

local CombatService = {}

local lastSwing: { [Player]: number } = {}
local activatedConnections: { [Player]: RBXScriptConnection } = {}

local function isEnemy(attacker: Player, victim: Player): boolean
	if attacker == victim then
		return false
	end
	local a = PlayerState.get(attacker)
	local v = PlayerState.get(victim)
	return a.duelId ~= nil and a.duelId == v.duelId and a.team ~= v.team
end

local function swing(player: Player)
	local now = os.clock()
	if now - (lastSwing[player] or 0) < Weapons.Tag.CooldownSeconds then
		return
	end
	lastSwing[player] = now

	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end

	local center = root.CFrame * CFrame.new(0, 0, -Weapons.Tag.Range / 2)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local hit: { [Player]: boolean } = {}
	for _, part in Workspace:GetPartBoundsInBox(center, Weapons.Tag.HitboxSize, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		local victim = if model then Players:GetPlayerFromCharacter(model) else nil
		if model and victim and not hit[victim] and isEnemy(player, victim) then
			local victimHumanoid = model:FindFirstChildOfClass("Humanoid")
			if victimHumanoid and victimHumanoid.Health > 0 then
				hit[victim] = true
				victimHumanoid:TakeDamage(Weapons.Tag.Damage)
				Log.debug(`Combat: {player.Name} tagged {victim.Name}`)
			end
		end
	end
end

-- Remove the player's weapon (round over, death, leave).
function CombatService.disarm(player: Player)
	local connection = activatedConnections[player]
	if connection then
		connection:Disconnect()
		activatedConnections[player] = nil
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		local tool = backpack:FindFirstChild(TOOL_NAME)
		if tool then
			tool:Destroy()
		end
	end
	local character = player.Character
	if character then
		local tool = character:FindFirstChild(TOOL_NAME)
		if tool then
			tool:Destroy()
		end
	end
end

-- Give the player the Tag tool and equip it. DuelService calls this when a round goes Live.
function CombatService.arm(player: Player)
	CombatService.disarm(player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not backpack then
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Tag: click to eliminate"
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 2)
	handle.Color = Color3.fromRGB(255, 80, 80)
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	activatedConnections[player] = tool.Activated:Connect(function()
		swing(player)
	end)
	tool.Parent = backpack

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

function CombatService.start()
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		CombatService.disarm(player)
	end)
end

return CombatService
