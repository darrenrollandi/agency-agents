--!strict
-- FxController: readable, bloodless feedback. Death poof + sound for any character, a red screen
-- flash + grunt when you take damage, and centre-screen announcements (FIGHT!, ROUND WON, ...).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Trove = require(Shared.Util.Trove)
local Net = require(Shared.Net.Net)
local Hud = require(script.Parent.Parent.Hud)
local SoundController = require(script.Parent.Parent.SoundController)

local HURT_COOLDOWN = 0.25
local KILL_FEED_LINES = 5
local KILL_FEED_SECONDS = 6
local KILL_FEED_LINE_HEIGHT = 26

local player = Players.LocalPlayer

local FxController = {}

local announceLabel: TextLabel
local damageFlash: Frame
local killFeed: Frame
local killLines: { TextLabel } = {}
local announceToken = 0
local lastHurtAt = 0
local characterTroves: { [Player]: Trove.Trove } = {}

-- A burst of grey-white particles where a character fell. No blood, ever (Mild label).
local function poof(position: Vector3)
	local part = Instance.new("Part")
	part.Name = "Poof"
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = Workspace.CurrentCamera

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(235, 235, 245), Color3.fromRGB(160, 160, 180))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0.1, 1)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = part
	emitter:Emit(30)

	task.delay(1.5, function()
		part:Destroy()
	end)
end

local function onDeath(who: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	local position = if root and root:IsA("BasePart")
		then root.Position
		else character:GetPivot().Position
	poof(position)
	if who == player then
		SoundController.play("Death")
	else
		SoundController.playAt("Death", position)
	end
end

local function flashDamage()
	damageFlash.BackgroundTransparency = 0.55
	TweenService
		:Create(damageFlash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		:Play()
end

local function watchCharacter(who: Player, character: Model)
	local trove = characterTroves[who]
	if not trove then
		trove = Trove.new()
		characterTroves[who] = trove
	end
	trove:clean()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	trove:connect(humanoid.Died, function()
		onDeath(who, character)
	end)
	if who == player then
		local lastHealth = humanoid.Health
		trove:connect(humanoid.HealthChanged, function(health: number)
			if health < lastHealth and health > 0 and os.clock() - lastHurtAt > HURT_COOLDOWN then
				lastHurtAt = os.clock()
				flashDamage()
				SoundController.play("Hurt")
			end
			lastHealth = health
		end)
	end
end

local function watchPlayer(who: Player)
	who.CharacterAdded:Connect(function(character)
		watchCharacter(who, character)
	end)
	local character = who.Character
	if character then
		watchCharacter(who, character)
	end
end

local function layoutKillFeed()
	for index, line in killLines do
		line.Position = UDim2.fromOffset(0, (index - 1) * KILL_FEED_LINE_HEIGHT)
	end
end

-- One kill-feed line, newest at the bottom, oldest dropped past five or after a few seconds.
local function addKillLine(
	attackerName: string,
	victimName: string,
	weapon: string,
	headshot: boolean
)
	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, 0, 0, KILL_FEED_LINE_HEIGHT)
	line.BackgroundTransparency = 1
	line.Font = Enum.Font.GothamBold
	line.TextSize = 18
	line.TextXAlignment = Enum.TextXAlignment.Right
	line.TextStrokeTransparency = 0.4
	local icon = if weapon == "Knife" then "🔪" else "•"
	local mine = attackerName == player.Name
	local victimMine = victimName == player.Name
	line.TextColor3 = if mine
		then Color3.fromRGB(120, 220, 140)
		elseif victimMine then Color3.fromRGB(240, 100, 100)
		else Color3.fromRGB(220, 220, 220)
	line.Text = `{attackerName}  {icon}{if headshot then " HEADSHOT" else ""}  {victimName}`
	line.Parent = killFeed
	table.insert(killLines, line)
	while #killLines > KILL_FEED_LINES do
		local oldest = table.remove(killLines, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	layoutKillFeed()
	task.delay(KILL_FEED_SECONDS, function()
		local index = table.find(killLines, line)
		if index then
			table.remove(killLines, index)
			line:Destroy()
			layoutKillFeed()
		end
	end)
end

-- Big centre-screen text that fades after `seconds`.
function FxController.announce(text: string, color: Color3, seconds: number)
	announceToken += 1
	local token = announceToken
	announceLabel.Text = text
	announceLabel.TextColor3 = color
	announceLabel.TextTransparency = 0
	announceLabel.TextStrokeTransparency = 0.3
	task.delay(seconds, function()
		if announceToken ~= token then
			return
		end
		TweenService:Create(announceLabel, TweenInfo.new(0.4), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)
end

function FxController.start()
	announceLabel = Hud.element("AnnounceLabel") :: TextLabel
	damageFlash = Hud.element("DamageFlash") :: Frame
	killFeed = Hud.element("KillFeed") :: Frame
	Net.onClient("KillFeed", addKillLine)

	Players.PlayerAdded:Connect(watchPlayer)
	for _, who in Players:GetPlayers() do
		watchPlayer(who)
	end
	Players.PlayerRemoving:Connect(function(who)
		local trove = characterTroves[who]
		if trove then
			trove:clean()
		end
		characterTroves[who] = nil
	end)
end

return FxController
