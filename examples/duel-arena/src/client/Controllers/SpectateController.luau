--!strict
-- SpectateController: while you're dead in a live round (team modes), follow a living teammate in
-- third person instead of staring at the spot you fell. Falls back to an opponent in 1v1. Restores
-- first person the moment your next character spawns.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net.Net)
local Hud = require(script.Parent.Parent.Hud)

local RETARGET_INTERVAL = 0.5
local SPECTATE_ZOOM = 12

local player = Players.LocalPlayer

local SpectateController = {}

local duel: Types.DuelUpdate? = nil
local target: Player? = nil
local lastCheck = 0
local statusLabel: TextLabel

local function aliveHumanoid(who: Player): Humanoid?
	local character = who.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return if humanoid
			and humanoid.Health > 0
			and character
			and character.Parent
		then humanoid
		else nil
end

local function myTeam(): Types.TeamId?
	return if duel then duel.team else nil
end

-- A living teammate, else a living opponent, else nil.
local function pickTarget(): Player?
	local update = duel
	if not update then
		return nil
	end
	local best: Player? = nil
	for _, entry in update.roster do
		if entry.name == player.Name then
			continue
		end
		local who = Players:FindFirstChild(entry.name)
		if not who or not who:IsA("Player") or not aliveHumanoid(who) then
			continue
		end
		if entry.team == myTeam() then
			return who
		end
		best = best or who
	end
	return best
end

local function stopSpectating()
	if not target then
		return
	end
	target = nil
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	local own = aliveHumanoid(player)
	if own then
		Workspace.CurrentCamera.CameraSubject = own
	end
	statusLabel.Text = ""
end

local function spectate(who: Player)
	local humanoid = aliveHumanoid(who)
	if not humanoid then
		return
	end
	target = who
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = SPECTATE_ZOOM
	player.CameraMinZoomDistance = SPECTATE_ZOOM
	Workspace.CurrentCamera.CameraSubject = humanoid
	statusLabel.Text = `Spectating {who.Name}`
end

local function tick()
	local update = duel
	local inLiveRound = update ~= nil and (update.state == "Live" or update.state == "RoundOver")
	if not inLiveRound or aliveHumanoid(player) then
		stopSpectating()
		return
	end
	if target and aliveHumanoid(target) then
		return
	end
	local next = pickTarget()
	if next then
		spectate(next)
	else
		stopSpectating()
	end
end

function SpectateController.start()
	statusLabel = Hud.element("NotifyLabel") :: TextLabel
	Net.onClient("DuelUpdate", function(update: Types.DuelUpdate)
		duel = if update.state == "Cleanup" then nil else update
		tick()
	end)
	player.CharacterAdded:Connect(function()
		-- Fresh character: back to first person on ourselves.
		task.defer(stopSpectating)
	end)
	RunService.Heartbeat:Connect(function()
		if os.clock() - lastCheck < RETARGET_INTERVAL then
			return
		end
		lastCheck = os.clock()
		tick()
	end)
end

return SpectateController
