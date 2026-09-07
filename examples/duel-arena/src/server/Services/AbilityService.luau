--!strict
-- AbilityService: cooldowns and server-side execution of abilities. The server owns every cooldown
-- and every effect that touches state (ammo, damage, health); the client only plays VFX and, for
-- Dash, moves its own character (which it owns anyway). Cooldowns reset each round.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Abilities = require(Shared.Config.Abilities)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local CombatService = require(script.Parent.CombatService)

type AbilityId = Abilities.AbilityId
type AbilityDef = Abilities.AbilityDef

local AbilityService = {}

-- readyAt (server time) per ability, present only while the player is armed.
local cooldowns: { [Player]: { [AbilityId]: number } } = {}
-- Bumped on disarm so lingering effects (heal ticks) stop.
local generation: { [Player]: number } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function publish(player: Player, def: AbilityDef, readyAt: number?)
	player:SetAttribute(Abilities.cooldownAttribute(def.id), readyAt)
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- Each handler returns true if the ability actually fired (and so goes on cooldown).
local handlers: { [AbilityId]: (Player, AbilityDef) -> boolean } = {
	SpeedLoader = function(player)
		return CombatService.refill(player)
	end,

	DeadEye = function(player, def)
		return CombatService.empowerNextShot(
			player,
			def.params.Multiplier,
			def.params.WindowSeconds
		)
	end,

	Dash = function(player)
		-- Movement is applied by the owning client on AbilityUsed; the server only gates the cooldown.
		return humanoidOf(player) ~= nil
	end,

	SecondWind = function(player, def)
		local humanoid = humanoidOf(player)
		if not humanoid or humanoid.Health >= humanoid.MaxHealth then
			return false
		end
		local ticks = 8
		local perTick = def.params.Heal / ticks
		local interval = def.params.DurationSeconds / ticks
		local myGeneration = generation[player]
		task.spawn(function()
			for _ = 1, ticks do
				task.wait(interval)
				if generation[player] ~= myGeneration then
					return
				end
				local current = humanoidOf(player)
				if not current then
					return
				end
				current.Health = math.min(current.MaxHealth, current.Health + perTick)
			end
		end)
		return true
	end,
}

local function onUse(player: Player, slot: number)
	local playerCooldowns = cooldowns[player]
	if not playerCooldowns then
		return
	end
	local weapon = CombatService.currentWeapon(player)
	if not weapon then
		return
	end
	local def = Abilities.get(weapon, slot)
	if not def then
		return
	end
	local t = now()
	if (playerCooldowns[def.id] or 0) > t then
		return
	end
	local handler = handlers[def.id]
	if not handler then
		Log.warn(`AbilityService: no handler for {def.id}`)
		return
	end
	if not handler(player, def) then
		return
	end
	local readyAt = t + def.cooldownSeconds
	playerCooldowns[def.id] = readyAt
	publish(player, def, readyAt)
	Net.fireAllClients("AbilityUsed", player, def.id)
	Log.debug(`Ability: {player.Name} used {def.id}`)
end

-- Fresh cooldowns for a new round. Call after CombatService.arm.
function AbilityService.arm(player: Player)
	cooldowns[player] = {}
	generation[player] = (generation[player] or 0) + 1
	for _, def in Abilities.Defs do
		publish(player, def, nil)
	end
end

-- Stop everything for this player (round over, death, leave).
function AbilityService.disarm(player: Player)
	cooldowns[player] = nil
	generation[player] = (generation[player] or 0) + 1
	for _, def in Abilities.Defs do
		publish(player, def, nil)
	end
end

function AbilityService.start()
	Net.onServer("UseAbility", onUse)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
		generation[player] = nil
	end)
end

return AbilityService
