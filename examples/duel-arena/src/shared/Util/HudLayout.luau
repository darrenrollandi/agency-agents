--!strict
-- HudLayout: builds the P1 DuelHud ScreenGui. The canonical copy lives in StarterGui (created once via
-- execute_luau and edited in Studio); the client only calls build() as a fallback when it's missing.
local HudLayout = {}

HudLayout.Name = "DuelHud"

local function label(
	parent: Instance,
	name: string,
	y: number,
	height: number,
	color: Color3
): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = UDim2.new(0.5, 0, 0, y)
	text.Size = UDim2.new(0.7, 0, 0, height)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextColor3 = color
	text.TextStrokeTransparency = 0.4
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
	label(gui, "ScoreLabel", 16, 44, Color3.new(1, 1, 1))
	label(gui, "StatusLabel", 64, 30, Color3.fromRGB(230, 230, 230))
	label(gui, "NotifyLabel", 104, 24, Color3.fromRGB(255, 200, 80))
	return gui
end

return HudLayout
