--!strict
-- LobbyController: the top HUD lines (queue status, duel scoreboard and state, server notices), the
-- lobby panel (level line and what to do next) and the results panel shown from DuelOver to Cleanup.
-- HudController owns health, ammo, crosshair and hit marker.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local XP = require(Shared.Config.XP)
local Skins = require(Shared.Config.Skins)
local Net = require(Shared.Net.Net)
local Hud = require(script.Parent.Parent.Hud)
local SoundController = require(script.Parent.Parent.SoundController)
local FxController = require(script.Parent.FxController)

local NOTIFY_SECONDS = 3
local RENDER_INTERVAL = 0.1
local LOBBY_HINT = "Stand on the blue pad to duel   ·   [L] Locker   ·   [Tab] Settings"

local player = Players.LocalPlayer

local LobbyController = {}

local scoreLabel: TextLabel
local statusLabel: TextLabel
local notifyLabel: TextLabel
local lobbyPanel: Frame
local lobbyLevel: TextLabel
local results: Frame
local resultsTitle: TextLabel
local resultsScore: TextLabel
local resultsXP: TextLabel
local resultsUnlock: TextLabel
local resultsHint: TextLabel

local queue: Types.QueueStatus? = nil
local duel: Types.DuelUpdate? = nil
local notifyToken = 0
local lastRender = 0
local lastState: Types.DuelState? = nil
local lastSuddenDeath = false
local lastTick = 0

local GOLD = Color3.fromRGB(255, 200, 80)
local GREEN = Color3.fromRGB(120, 220, 140)
local RED = Color3.fromRGB(240, 100, 100)
local GREY = Color3.fromRGB(220, 220, 220)

-- Announcements and sounds on state changes; called for every DuelUpdate.
local function onStateChange(update: Types.DuelUpdate)
	if update.state ~= lastState then
		lastState = update.state
		if update.state == "Countdown" then
			lastTick = 0
		elseif update.state == "Live" then
			FxController.announce("FIGHT!", GOLD, 0.9)
			SoundController.play("Fight")
		elseif update.state == "RoundOver" then
			if update.roundWinner == nil then
				FxController.announce("DRAW", GREY, 1.5)
			elseif update.roundWinner == update.team then
				FxController.announce("ROUND WON", GREEN, 1.5)
				SoundController.play("RoundWon")
			else
				FxController.announce("ROUND LOST", RED, 1.5)
				SoundController.play("RoundLost")
			end
		end
	end
	if update.state == "Live" and update.suddenDeath and not lastSuddenDeath then
		FxController.announce("SUDDEN DEATH", RED, 1.5)
		SoundController.play("RoundLost")
	end
	lastSuddenDeath = update.suddenDeath
end

-- 3, 2, 1 during the countdown.
local function tickCountdown(update: Types.DuelUpdate)
	local endsAt = update.countdownEndsAt
	if update.state ~= "Countdown" or not endsAt then
		return
	end
	local remaining = math.ceil(endsAt - Workspace:GetServerTimeNow())
	if remaining ~= lastTick and remaining >= 1 and remaining <= 3 then
		lastTick = remaining
		FxController.announce(tostring(remaining), GREY, 0.5)
		SoundController.play("Tick")
	end
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
		return "Duel over"
	end
	return ""
end

local function renderLobbyLevel()
	local level = player:GetAttribute("Level")
	local xp = player:GetAttribute("XP")
	if typeof(level) ~= "number" or typeof(xp) ~= "number" then
		lobbyLevel.Text = "Loading your data…"
		return
	end
	if level >= XP.MaxLevel then
		lobbyLevel.Text = `LEVEL {level}   ·   MAX`
	else
		lobbyLevel.Text = `LEVEL {level}   ·   {xp} / {XP.xpForLevel(level + 1)} XP`
	end
end

local function showResults(update: Types.DuelUpdate)
	local mine = update.duelWinner == update.team
	if update.duelWinner == nil then
		resultsTitle.Text = "DRAW"
		resultsTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
	elseif mine then
		resultsTitle.Text = "VICTORY"
		resultsTitle.TextColor3 = Color3.fromRGB(120, 220, 140)
	else
		resultsTitle.Text = "DEFEAT"
		resultsTitle.TextColor3 = Color3.fromRGB(240, 100, 100)
	end
	local yours = if update.team == "A" then update.scoreA else update.scoreB
	local theirs = if update.team == "A" then update.scoreB else update.scoreA
	resultsScore.Text = `{yours}  -  {theirs}{if update.forfeit then "   (opponent left)" else ""}`
	resultsXP.Text = ""
	resultsUnlock.Text = ""
	resultsHint.Text = "Back to the lobby in a moment"
	results.Visible = true
end

local function hideResults()
	results.Visible = false
end

local function onReward(reward: Types.DuelReward)
	-- The reward can arrive a frame before or after the DuelOver update; render whenever it lands.
	local boost = if reward.boosted then "   (×2 boost)" else ""
	local up = if reward.leveledUp then "   ▲ LEVEL UP" else ""
	resultsXP.Text = `+{reward.xpGained} XP{boost}   ·   Level {reward.level}{up}`
	if #reward.unlocked > 0 then
		local names = {}
		for _, skinId in reward.unlocked do
			local def = Skins.get(skinId)
			table.insert(names, if def then def.name else skinId)
		end
		resultsUnlock.Text = `Unlocked: {table.concat(names, ", ")}   ·   equip it in the Locker`
	end
end

local function render()
	lastRender = os.clock()
	local update = duel
	lobbyPanel.Visible = update == nil
	if update then
		tickCountdown(update)
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
	scoreLabel = Hud.element("ScoreLabel") :: TextLabel
	statusLabel = Hud.element("StatusLabel") :: TextLabel
	notifyLabel = Hud.element("NotifyLabel") :: TextLabel
	lobbyPanel = Hud.element("LobbyPanel") :: Frame
	lobbyLevel = Hud.element("LobbyLevel") :: TextLabel
	results = Hud.element("ResultsPanel") :: Frame
	resultsTitle = Hud.element("ResultsTitle") :: TextLabel
	resultsScore = Hud.element("ResultsScore") :: TextLabel
	resultsXP = Hud.element("ResultsXP") :: TextLabel
	resultsUnlock = Hud.element("ResultsUnlock") :: TextLabel
	resultsHint = Hud.element("ResultsHint") :: TextLabel
	local lobbyHint = Hud.element("LobbyHint") :: TextLabel
	lobbyHint.Text = LOBBY_HINT

	Net.onClient("QueueStatus", function(status: Types.QueueStatus?)
		queue = status
		render()
	end)
	Net.onClient("DuelUpdate", function(update: Types.DuelUpdate)
		if update.state == "Cleanup" then
			duel = nil
			lastState = nil
			lastSuddenDeath = false
			hideResults()
		else
			duel = update
			onStateChange(update)
			if update.state == "DuelOver" then
				showResults(update)
			end
		end
		render()
	end)
	Net.onClient("DuelReward", onReward)
	Net.onClient("Notify", function(message: string)
		notify(message)
	end)
	for _, attribute in { "Level", "XP" } do
		player:GetAttributeChangedSignal(attribute):Connect(renderLobbyLevel)
	end
	RunService.Heartbeat:Connect(function()
		local update = duel
		local ticking = update and (update.countdownEndsAt or update.roundEndsAt)
		if ticking and os.clock() - lastRender >= RENDER_INTERVAL then
			render()
		end
	end)
	renderLobbyLevel()
	render()
end

return LobbyController
