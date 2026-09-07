--!strict
-- HudLayout: builds the DuelHud ScreenGui. The canonical copy lives in StarterGui (created once via
-- execute_luau and edited in Studio); the client only calls build() as a fallback when it's missing.
-- Elements are found by name, so renaming here means renaming in the place.
local HudLayout = {}

HudLayout.Name = "DuelHud"

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

function HudLayout.build(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = HudLayout.Name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local white = Color3.new(1, 1, 1)
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
		white,
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
		Color3.fromRGB(255, 200, 80),
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
		white,
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
		white,
		Enum.TextXAlignment.Right
	)

	-- Centre: crosshair dot and hit marker.
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(4, 4)
	crosshair.BackgroundColor3 = white
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
		white,
		center
	)
	hitMarker.Text = "×"
	hitMarker.TextTransparency = 1

	return gui
end

return HudLayout
