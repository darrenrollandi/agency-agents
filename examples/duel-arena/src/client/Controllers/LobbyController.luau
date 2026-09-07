--!strict
-- LobbyController: shows pad queue status, the duel scoreboard and server notices on the P1 HUD.
-- HudController takes over the in-duel HUD in P5; this stays responsible for the lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local HudLayout = require(Shared.Util.HudLayout)

local NOTIFY_SECONDS = 3
local RENDER_INTERVAL = 0.1

local player = Players.LocalPlayer

local LobbyController = {}

local scoreLabel: TextLabel
local statusLabel: TextLabel
local notifyLabel: TextLabel
local queue: Types.QueueStatus? = nil
local duel: Types.DuelUpdate? = nil
local notifyToken = 0
local lastRender = 0

local function getHud(): ScreenGui
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(HudLayout.Name, 5)
	if not gui then
		Log.warn(
			`StarterGui.{HudLayout.Name} is missing; built a fallback. Run the P1 setup snippet and save the place.`
		)
		gui = HudLayout.build()
		gui.Parent = playerGui
	end
	return gui :: ScreenGui
end

local function formatClock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function duelStatus(update: Types.DuelUpdate): string
	local now = Workspace:GetServerTimeNow()
	if update.state == "Countdown" then
		local remaining = math.max(1, math.ceil((update.countdownEndsAt or now) - now))
		return `Round {update.round} starts in {remaining}`
	elseif update.state == "Live" then
		local alive = `alive {update.aliveA} - {update.aliveB}`
		if update.suddenDeath then
			return `SUDDEN DEATH  ·  {alive}`
		end
		return `Round {update.round}  ·  {formatClock((update.roundEndsAt or now) - now)}  ·  {alive}`
	elseif update.state == "RoundOver" then
		if update.roundWinner == nil then
			return "Round drawn"
		end
		return if update.roundWinner == update.team
			then "You won the round"
			else "You lost the round"
	elseif update.state == "DuelOver" then
		local suffix = if update.forfeit then "  (opponent left)" else ""
		if update.duelWinner == nil then
			return "Duel drawn" .. suffix
		end
		return (if update.duelWinner == update.team then "VICTORY" else "DEFEAT") .. suffix
	end
	return ""
end

local function render()
	lastRender = os.clock()
	local update = duel
	if update then
		scoreLabel.Text = `Team {update.team}   ·   A {update.scoreA} - {update.scoreB} B`
		statusLabel.Text = duelStatus(update)
	elseif queue then
		scoreLabel.Text = ""
		statusLabel.Text =
			`Queued for {queue.mode} ({queue.count}/{queue.needed}).  Step off the pad to leave.`
	else
		scoreLabel.Text = ""
		statusLabel.Text = ""
	end
end

local function notify(message: string)
	notifyToken += 1
	local token = notifyToken
	notifyLabel.Text = message
	task.delay(NOTIFY_SECONDS, function()
		if notifyToken == token then
			notifyLabel.Text = ""
		end
	end)
end

function LobbyController.start()
	local gui = getHud()
	scoreLabel = gui:WaitForChild("ScoreLabel") :: TextLabel
	statusLabel = gui:WaitForChild("StatusLabel") :: TextLabel
	notifyLabel = gui:WaitForChild("NotifyLabel") :: TextLabel

	Net.onClient("QueueStatus", function(status: Types.QueueStatus?)
		queue = status
		render()
	end)
	Net.onClient("DuelUpdate", function(update: Types.DuelUpdate)
		duel = if update.state == "Cleanup" then nil else update
		render()
	end)
	Net.onClient("Notify", function(message: string)
		notify(message)
	end)
	RunService.Heartbeat:Connect(function()
		local update = duel
		local ticking = update and (update.countdownEndsAt or update.roundEndsAt)
		if ticking and os.clock() - lastRender >= RENDER_INTERVAL then
			render()
		end
	end)
	render()
end

return LobbyController
