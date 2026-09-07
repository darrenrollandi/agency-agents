--!strict
-- AntiCheatService: log-only movement sanity check. Every half second it compares each armed
-- player's horizontal travel with what WalkSpeed (plus a Dash allowance) permits and counts a flag when
-- it's exceeded. It never kicks or teleports: tune the thresholds against real players first, then
-- decide with D whether flags should become actions. Flags are visible via DebugCommands "flags".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Abilities = require(Shared.Config.Abilities)
local Log = require(Shared.Util.Log)
local CombatService = require(script.Parent.CombatService)

local SAMPLE_INTERVAL = 0.5
-- Allowed speed = WalkSpeed × this (latency, slopes, physics jitter).
local SPEED_TOLERANCE = 1.6
-- Extra horizontal studs allowed in a sample that overlaps a Dash.
local DASH_ALLOWANCE = Abilities.Defs.Dash.params.Speed * Abilities.Defs.Dash.params.DurationSeconds
	+ 4

type Sample = { character: Model, position: Vector3, at: number }

local AntiCheatService = {}

local samples: { [Player]: Sample } = {}
local flags: { [Player]: number } = {}
local warned: { [Player]: boolean } = {}

local function dashedRecently(player: Player, now: number): boolean
	local readyAt = player:GetAttribute(Abilities.cooldownAttribute("Dash"))
	if typeof(readyAt) ~= "number" then
		return false
	end
	local usedAt = readyAt - Abilities.Defs.Dash.cooldownSeconds
	return now - usedAt < SAMPLE_INTERVAL * 2
end

local function check(player: Player, now: number)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not root or not root:IsA("BasePart") then
		samples[player] = nil
		return
	end
	local previous = samples[player]
	samples[player] = { character = character, position = root.Position, at = now }
	-- A new character (respawn/teleport) or no baseline: nothing to compare yet.
	if not previous or previous.character ~= character or not CombatService.isArmed(player) then
		return
	end
	local dt = now - previous.at
	if dt <= 0 then
		return
	end
	local delta = root.Position - previous.position
	local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local allowed = StarterPlayer.CharacterWalkSpeed * SPEED_TOLERANCE * dt
	if dashedRecently(player, now) then
		allowed += DASH_ALLOWANCE
	end
	if horizontal > allowed then
		flags[player] = (flags[player] or 0) + 1
		if not warned[player] then
			warned[player] = true
			Log.warn(
				`AntiCheat: {player.Name} moved {string.format("%.1f", horizontal)} studs in {string.format(
					"%.2f",
					dt
				)} s (allowed {string.format("%.1f", allowed)}); further flags are silent`
			)
		end
	end
end

-- Movement flags so far for a player.
function AntiCheatService.getFlags(player: Player): number
	return flags[player] or 0
end

function AntiCheatService.start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < SAMPLE_INTERVAL then
			return
		end
		elapsed = 0
		local now = Workspace:GetServerTimeNow()
		for _, player in Players:GetPlayers() do
			check(player, now)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		samples[player] = nil
		flags[player] = nil
		warned[player] = nil
	end)
end

return AntiCheatService
