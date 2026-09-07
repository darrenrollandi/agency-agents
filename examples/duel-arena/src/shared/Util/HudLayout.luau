--!strict
-- HudLayout: builds the DuelHud ScreenGui. The canonical copy lives in StarterGui (created once via
-- the setup snippet in STATUS.md and edited in Studio); the client only calls build() as a fallback
-- when it's missing or outdated. Controllers find elements by unique name (recursive), so renaming
-- here means renaming in the place.
local HudLayout = {}

HudLayout.Name = "DuelHud"

local WHITE = Color3.new(1, 1, 1)
local GREY = Color3.fromRGB(180, 180, 190)
local GOLD = Color3.fromRGB(255, 200, 80)

local function label(
	parent: Instance,
	name: string,
	anchor: Vector2,
	position: UDim2,
	size: UDim2,
	textSize: number,
	color: Color3,
	alignment: Enum.TextXAlignment
): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.AnchorPoint = anchor
	text.Position = position
	text.Size = size
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = textSize
	text.TextColor3 = color
	text.TextStrokeTransparency = 0.4
	text.TextXAlignment = alignment
	text.Text = ""
	text.Parent = parent
	return text
end

local function centeredLabel(
	parent: Instance,
	name: string,
	y: number,
	height: number,
	textSize: number,
	color: Color3
): TextLabel
	return label(
		parent,
		name,
		Vector2.new(0.5, 0),
		UDim2.new(0.5, 0, 0, y),
		UDim2.new(1, -40, 0, height),
		textSize,
		color,
		Enum.TextXAlignment.Center
	)
end

-- A hidden, centred, dark rounded panel.
local function panel(parent: Instance, name: string, width: number, height: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(width, height)
	frame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	return frame
end

local function button(parent: Instance, name: string, position: UDim2, text: string): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = position
	b.Size = UDim2.fromOffset(44, 36)
	b.BackgroundColor3 = Color3.fromRGB(52, 56, 68)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 22
	b.TextColor3 = WHITE
	b.Text = text
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	return b
end

function HudLayout.build(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = HudLayout.Name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local top = Vector2.new(0.5, 0)
	local center = Enum.TextXAlignment.Center

	-- Top centre: score, state line, notices.
	label(
		gui,
		"ScoreLabel",
		top,
		UDim2.new(0.5, 0, 0, 16),
		UDim2.new(0.7, 0, 0, 44),
		36,
		WHITE,
		center
	)
	label(
		gui,
		"StatusLabel",
		top,
		UDim2.new(0.5, 0, 0, 64),
		UDim2.new(0.7, 0, 0, 30),
		24,
		Color3.fromRGB(230, 230, 230),
		center
	)
	label(
		gui,
		"NotifyLabel",
		top,
		UDim2.new(0.5, 0, 0, 104),
		UDim2.new(0.7, 0, 0, 24),
		20,
		GOLD,
		center
	)

	-- Bottom left: health. Bottom right: weapon + ammo.
	label(
		gui,
		"HealthLabel",
		Vector2.new(0, 1),
		UDim2.new(0, 32, 1, -28),
		UDim2.fromOffset(240, 44),
		40,
		WHITE,
		Enum.TextXAlignment.Left
	)
	label(
		gui,
		"WeaponLabel",
		Vector2.new(1, 1),
		UDim2.new(1, -32, 1, -68),
		UDim2.fromOffset(240, 24),
		18,
		Color3.fromRGB(200, 200, 200),
		Enum.TextXAlignment.Right
	)
	label(
		gui,
		"AmmoLabel",
		Vector2.new(1, 1),
		UDim2.new(1, -32, 1, -28),
		UDim2.fromOffset(240, 44),
		40,
		WHITE,
		Enum.TextXAlignment.Right
	)

	-- Bottom centre: the two ability slots for the weapon in hand.
	label(
		gui,
		"Ability1Label",
		Vector2.new(0.5, 1),
		UDim2.new(0.5, 0, 1, -56),
		UDim2.fromOffset(420, 24),
		20,
		Color3.fromRGB(220, 220, 220),
		center
	)
	label(
		gui,
		"Ability2Label",
		Vector2.new(0.5, 1),
		UDim2.new(0.5, 0, 1, -28),
		UDim2.fromOffset(420, 24),
		20,
		Color3.fromRGB(220, 220, 220),
		center
	)

	-- Centre: crosshair dot and hit marker.
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(4, 4)
	crosshair.BackgroundColor3 = WHITE
	crosshair.BorderSizePixel = 0
	crosshair.Visible = false
	crosshair.Parent = gui

	local hitMarker = label(
		gui,
		"HitMarker",
		Vector2.new(0.5, 0.5),
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromOffset(60, 60),
		44,
		WHITE,
		center
	)
	hitMarker.Text = "×"
	hitMarker.TextTransparency = 1

	-- Lobby: level line and the three things you can do. Shown only outside a duel.
	local lobby = Instance.new("Frame")
	lobby.Name = "LobbyPanel"
	lobby.AnchorPoint = Vector2.new(0.5, 1)
	lobby.Position = UDim2.new(0.5, 0, 1, -100)
	lobby.Size = UDim2.fromOffset(760, 70)
	lobby.BackgroundTransparency = 1
	lobby.Parent = gui
	centeredLabel(lobby, "LobbyLevel", 0, 30, 24, WHITE)
	centeredLabel(lobby, "LobbyHint", 34, 30, 22, GOLD)

	-- Results: shown from DuelOver until Cleanup.
	local results = panel(gui, "ResultsPanel", 560, 320)
	centeredLabel(results, "ResultsTitle", 28, 60, 52, WHITE)
	centeredLabel(results, "ResultsScore", 96, 44, 36, Color3.fromRGB(230, 230, 230))
	centeredLabel(results, "ResultsXP", 156, 34, 26, GOLD)
	centeredLabel(results, "ResultsUnlock", 196, 30, 22, Color3.fromRGB(120, 220, 140))
	centeredLabel(results, "ResultsHint", 264, 26, 18, GREY)

	-- Settings: Tab. Rows are adjusted with the buttons or ← → after selecting with ↑ ↓.
	local settings = panel(gui, "SettingsPanel", 560, 300)
	centeredLabel(settings, "SettingsTitle", 22, 44, 34, WHITE).Text = "SETTINGS"
	centeredLabel(settings, "SensitivityRow", 96, 40, 26, WHITE)
	button(settings, "SensitivityMinus", UDim2.new(0.5, -200, 0, 116), "◄")
	button(settings, "SensitivityPlus", UDim2.new(0.5, 200, 0, 116), "►")
	centeredLabel(settings, "FovRow", 160, 40, 26, WHITE)
	button(settings, "FovMinus", UDim2.new(0.5, -200, 0, 180), "◄")
	button(settings, "FovPlus", UDim2.new(0.5, 200, 0, 180), "►")
	centeredLabel(settings, "SettingsHint", 246, 26, 16, GREY).Text =
		"Tab closes  ·  ↑ ↓ pick a row  ·  ← → or the arrows adjust"

	return gui
end

return HudLayout
