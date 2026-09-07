--!strict
-- LockerController: the skins locker. Toggled with L (gamepad Select) in the lobby only. The panel is
-- built in code because its rows are a dynamic list driven by Config/Skins and the player's
-- ProgressionSnapshot. Equipping sends EquipSkin; the server decides and republishes.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Skins = require(Shared.Config.Skins)
local Monetisation = require(Shared.Config.Monetisation)
local Net = require(Shared.Net.Net)
local MouseFree = require(script.Parent.Parent.MouseFree)

local ACTION_TOGGLE = "ToggleLocker"
local HOLD_KEY = "Locker"

local player = Players.LocalPlayer

local LockerController = {}

local gui: ScreenGui
local content: Frame
local subtitle: TextLabel
local snapshot: Types.ProgressionSnapshot? = nil
local open = false

local function makeLabel(parent: Instance, text: string, size: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.TextColor3 = color
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function buildGui(): ScreenGui
	local screen = Instance.new("ScreenGui")
	screen.Name = "LockerGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(720, 460)
	panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local title = makeLabel(panel, "LOCKER", 32, Color3.new(1, 1, 1))
	title.Position = UDim2.fromOffset(24, 16)
	title.Size = UDim2.new(1, -48, 0, 40)

	subtitle = makeLabel(panel, "", 16, Color3.fromRGB(180, 180, 190))
	subtitle.Position = UDim2.fromOffset(24, 56)
	subtitle.Size = UDim2.new(1, -48, 0, 22)

	local hint =
		makeLabel(panel, "L to close  ·  click a skin to equip", 14, Color3.fromRGB(140, 140, 150))
	hint.Position = UDim2.new(0, 24, 1, -30)
	hint.Size = UDim2.new(1, -48, 0, 20)

	content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(24, 90)
	content.Size = UDim2.new(1, -48, 1, -130)
	content.BackgroundTransparency = 1
	content.Parent = panel

	return screen
end

local function statusFor(
	def: Skins.SkinDef,
	snap: Types.ProgressionSnapshot
): (string, Color3, string?)
	local equipped = def.id == snap.equippedRevolver or def.id == snap.equippedKnife
	if equipped then
		return "EQUIPPED", Color3.fromRGB(120, 220, 140), nil
	end
	if table.find(snap.owned, def.id) then
		return "EQUIP", Color3.new(1, 1, 1), "equip"
	end
	if def.unlockLevel then
		return `Level {def.unlockLevel}`, Color3.fromRGB(150, 150, 160), nil
	end
	-- Game-pass skin: buyable once D has created the pass and set its id.
	if Monetisation.isConfigured(Monetisation.SkinPasses[def.id] or 0) then
		return "BUY  (Robux)", Color3.fromRGB(255, 200, 80), "buy"
	end
	return "Coming soon", Color3.fromRGB(150, 150, 160), nil
end

local function swatch(parent: Instance, palette: Skins.Palette)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(54, 18)
	frame.Position = UDim2.fromOffset(0, 4)
	frame.BackgroundColor3 = palette.Body
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(18, 18)
	accent.BackgroundColor3 = palette.Accent
	accent.BorderSizePixel = 0
	accent.Parent = frame
	local grip = Instance.new("Frame")
	grip.Size = UDim2.fromOffset(18, 18)
	grip.Position = UDim2.fromOffset(36, 0)
	grip.BackgroundColor3 = palette.Grip
	grip.BorderSizePixel = 0
	grip.Parent = frame
end

local function buildColumn(weapon: Types.WeaponId, x: number, snap: Types.ProgressionSnapshot)
	local column = Instance.new("Frame")
	column.Name = weapon
	column.Position = UDim2.fromScale(x, 0)
	column.Size = UDim2.new(0.5, -12, 1, 0)
	column.BackgroundTransparency = 1
	column.Parent = content

	local header = makeLabel(column, string.upper(weapon), 20, Color3.fromRGB(230, 230, 230))
	header.Size = UDim2.new(1, 0, 0, 28)

	for index, def in Skins.forWeapon(weapon) do
		local text, color, action = statusFor(def, snap)
		local row = Instance.new("TextButton")
		row.Name = def.id
		row.Position = UDim2.fromOffset(0, 32 + (index - 1) * 52)
		row.Size = UDim2.new(1, 0, 0, 46)
		row.BackgroundColor3 = Color3.fromRGB(38, 41, 50)
		row.BorderSizePixel = 0
		row.AutoButtonColor = action ~= nil
		row.Text = ""
		row.Parent = column
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local swatchHolder = Instance.new("Frame")
		swatchHolder.Position = UDim2.fromOffset(10, 10)
		swatchHolder.Size = UDim2.fromOffset(54, 26)
		swatchHolder.BackgroundTransparency = 1
		swatchHolder.Parent = row
		swatch(swatchHolder, def.palette)

		local name = makeLabel(row, def.name, 18, Color3.new(1, 1, 1))
		name.Position = UDim2.fromOffset(76, 0)
		name.Size = UDim2.new(1, -200, 1, 0)

		local status = makeLabel(row, text, 15, color)
		status.Position = UDim2.new(1, -124, 0, 0)
		status.Size = UDim2.fromOffset(112, 46)
		status.TextXAlignment = Enum.TextXAlignment.Right

		if action == "equip" then
			row.Activated:Connect(function()
				Net.fireServer("EquipSkin", def.id)
			end)
		elseif action == "buy" then
			row.Activated:Connect(function()
				Net.fireServer("RequestPurchase", "GamePass", def.id)
			end)
		end
	end
end

-- XP boost row under the columns. Hidden until D configures the developer product.
local function buildBoostRow(snap: Types.ProgressionSnapshot)
	local product = Monetisation.DevProducts.XPBoost
	local active = snap.boostUntil > os.time()
	if not Monetisation.isConfigured(product.id) and not active then
		return
	end
	local row = Instance.new("TextButton")
	row.Name = "XPBoost"
	row.Position = UDim2.new(0, 0, 1, -34)
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(58, 48, 30)
	row.BorderSizePixel = 0
	row.AutoButtonColor = not active
	row.Text = ""
	row.Parent = content
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local name = makeLabel(row, product.name, 16, Color3.fromRGB(255, 220, 140))
	name.Position = UDim2.fromOffset(12, 0)
	name.Size = UDim2.new(1, -200, 1, 0)

	local status = makeLabel(row, "", 15, Color3.new(1, 1, 1))
	status.Position = UDim2.new(1, -184, 0, 0)
	status.Size = UDim2.fromOffset(172, 34)
	status.TextXAlignment = Enum.TextXAlignment.Right
	if active then
		local minutes = math.ceil((snap.boostUntil - os.time()) / 60)
		status.Text = `ACTIVE  ·  {minutes} min left`
	else
		status.Text = "BUY  (Robux)"
		row.Activated:Connect(function()
			Net.fireServer("RequestPurchase", "Product", "XPBoost")
		end)
	end
end

local function render()
	for _, child in content:GetChildren() do
		child:Destroy()
	end
	local snap = snapshot
	if not snap then
		subtitle.Text = "Loading your data…"
		return
	end
	subtitle.Text =
		`Level {snap.level}   ·   {snap.xp} / {snap.nextLevelXP} XP   ·   {snap.wins}W {snap.losses}L`
	buildColumn("Revolver", 0, snap)
	buildColumn("Knife", 0.5, snap)
	buildBoostRow(snap)
end

local function setOpen(value: boolean)
	if open == value then
		return
	end
	open = value
	gui.Enabled = value
	-- Mirrored as an attribute so other UI (lobby menu, P5) and tests can open or close the locker.
	gui:SetAttribute("Open", value)
	if value then
		render()
		MouseFree.hold(HOLD_KEY)
	else
		MouseFree.release(HOLD_KEY)
	end
end

local function onToggle(_name: string, inputState: Enum.UserInputState, _input: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	-- Not during a duel.
	if player:GetAttribute("Weapon") ~= nil then
		return Enum.ContextActionResult.Pass
	end
	setOpen(not open)
	return Enum.ContextActionResult.Sink
end

-- Open or close the locker from other UI.
function LockerController.setOpen(value: boolean)
	if value and player:GetAttribute("Weapon") ~= nil then
		return
	end
	setOpen(value)
end

function LockerController.start()
	gui = buildGui()
	gui:SetAttribute("Open", false)
	gui.Parent = player:WaitForChild("PlayerGui")
	gui:GetAttributeChangedSignal("Open"):Connect(function()
		LockerController.setOpen(gui:GetAttribute("Open") == true)
	end)

	Net.onClient("ProgressionSnapshot", function(snap: Types.ProgressionSnapshot)
		snapshot = snap
		if open then
			render()
		end
	end)
	-- Entering a duel closes the locker.
	player:GetAttributeChangedSignal("Weapon"):Connect(function()
		if player:GetAttribute("Weapon") ~= nil then
			setOpen(false)
		end
	end)
	ContextActionService:BindAction(
		ACTION_TOGGLE,
		onToggle,
		false,
		Enum.KeyCode.L,
		Enum.KeyCode.ButtonSelect
	)
end

return LockerController
