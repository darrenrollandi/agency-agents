--!strict
-- AbilityController: Ability1 / Ability2 input, the two HUD slot lines with live cooldowns, and the
-- client-side effects of AbilityUsed. Dash movement is applied here by the owner (the client owns
-- its character's physics); everything that changes game state happens on the server.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Abilities = require(Shared.Config.Abilities)
local Net = require(Shared.Net.Net)
local Hud = require(script.Parent.Parent.Hud)
local SoundController = require(script.Parent.Parent.SoundController)

local ACTION_ABILITY_1 = "Ability1"
local ACTION_ABILITY_2 = "Ability2"
local RENDER_INTERVAL = 0.1
local KEY_HINTS = { "E", "F" }

local player = Players.LocalPlayer

local AbilityController = {}

local slotLabels: { TextLabel } = {}
local bound = false
local lastRender = 0

local function currentWeapon(): Types.WeaponId?
	local weapon = player:GetAttribute("Weapon")
	if weapon == "Revolver" or weapon == "Knife" then
		return weapon :: Types.WeaponId
	end
	return nil
end

local function readyAt(def: Abilities.AbilityDef): number
	local value = player:GetAttribute(Abilities.cooldownAttribute(def.id))
	return if typeof(value) == "number" then value else 0
end

local function render()
	lastRender = os.clock()
	local weapon = currentWeapon()
	for slot = 1, Abilities.Slots do
		local label = slotLabels[slot]
		local def = if weapon then Abilities.get(weapon, slot) else nil
		if not def then
			label.Text = ""
			continue
		end
		local remaining = readyAt(def) - Workspace:GetServerTimeNow()
		if remaining > 0 then
			label.Text = `[{KEY_HINTS[slot]}]  {def.name}   {string.format("%.1f", remaining)}s`
			label.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			label.Text = `[{KEY_HINTS[slot]}]  {def.name}   READY`
			label.TextColor3 = Color3.fromRGB(220, 220, 220)
		end
	end
end

local function use(slot: number)
	local weapon = currentWeapon()
	local def = if weapon then Abilities.get(weapon, slot) else nil
	if not def or readyAt(def) > Workspace:GetServerTimeNow() then
		return
	end
	Net.fireServer("UseAbility", slot)
end

local function onAction(actionName: string, inputState: Enum.UserInputState, _input: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	use(if actionName == ACTION_ABILITY_1 then 1 else 2)
	return Enum.ContextActionResult.Sink
end

local function bind()
	if bound then
		return
	end
	bound = true
	ContextActionService:BindAction(
		ACTION_ABILITY_1,
		onAction,
		false,
		Enum.KeyCode.E,
		Enum.KeyCode.ButtonL1
	)
	ContextActionService:BindAction(
		ACTION_ABILITY_2,
		onAction,
		false,
		Enum.KeyCode.F,
		Enum.KeyCode.ButtonR1
	)
end

local function unbind()
	if not bound then
		return
	end
	bound = false
	ContextActionService:UnbindAction(ACTION_ABILITY_1)
	ContextActionService:UnbindAction(ACTION_ABILITY_2)
end

-- Dash: a short LinearVelocity burst along the camera's flat look direction on our own character.
local function dash(def: Abilities.AbilityDef)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local look = Workspace.CurrentCamera.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = root.CFrame.LookVector
	end
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = flat.Unit * def.params.Speed
	velocity.Parent = root
	task.delay(def.params.DurationSeconds, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
end

-- A brief coloured pulse at a character's root, for abilities others should notice.
local function pulse(user: Player, color: Color3)
	local character = user.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(4, 4, 4)
	part.CFrame = root.CFrame
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0.6
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = Workspace.CurrentCamera
	task.delay(0.25, function()
		part:Destroy()
	end)
end

local function onAbilityUsed(user: Player, abilityId: string)
	local def = Abilities.Defs[abilityId :: Abilities.AbilityId]
	if not def then
		return
	end
	local soundName = if def.id == "Dash" then "Dash" else "Ability"
	if user == player then
		SoundController.play(soundName)
	else
		local character = user.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			SoundController.playAt(soundName, root.Position)
		end
	end
	if def.id == "Dash" then
		if user == player then
			dash(def)
		end
		pulse(user, Color3.fromRGB(120, 200, 255))
	elseif def.id == "SecondWind" then
		pulse(user, Color3.fromRGB(90, 230, 120))
	elseif def.id == "DeadEye" then
		pulse(user, Color3.fromRGB(255, 210, 60))
	end
end

function AbilityController.start()
	for slot = 1, Abilities.Slots do
		slotLabels[slot] = Hud.element(`Ability{slot}Label`) :: TextLabel
	end

	local function onWeaponAttribute()
		if currentWeapon() then
			bind()
		else
			unbind()
		end
		render()
	end
	player:GetAttributeChangedSignal("Weapon"):Connect(onWeaponAttribute)
	for _, def in Abilities.Defs do
		player:GetAttributeChangedSignal(Abilities.cooldownAttribute(def.id)):Connect(render)
	end
	onWeaponAttribute()

	Net.onClient("AbilityUsed", onAbilityUsed)

	RunService.Heartbeat:Connect(function()
		if currentWeapon() and os.clock() - lastRender >= RENDER_INTERVAL then
			render()
		end
	end)
end

return AbilityController
