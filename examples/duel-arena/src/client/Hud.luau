--!strict
-- Hud: finds the DuelHud ScreenGui for every controller. If the place's copy is missing or out of
-- date (lacks an element), it is replaced by a fresh HudLayout build with a warning so a playtest is
-- never blocked; the real fix is re-running the setup snippet in STATUS.md and saving the place.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudLayout = require(Shared.Util.HudLayout)
local Log = require(Shared.Util.Log)

local Hud = {}

local cached: ScreenGui? = nil

local function rebuild(playerGui: Instance, reason: string): ScreenGui
	Log.warn(
		`DuelHud {reason}; built a fallback. Run the setup snippet in STATUS.md and save the place.`
	)
	local old = playerGui:FindFirstChild(HudLayout.Name)
	if old then
		old:Destroy()
	end
	local gui = HudLayout.build()
	gui.Parent = playerGui
	return gui
end

function Hud.get(): ScreenGui
	local existing = cached
	if existing and existing.Parent then
		return existing
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(HudLayout.Name, 5)
	if not gui or not gui:IsA("ScreenGui") then
		gui = rebuild(playerGui, "is missing from StarterGui")
	end
	cached = gui :: ScreenGui
	return gui :: ScreenGui
end

-- A named element of the HUD. Rebuilds the whole HUD once if the place's layout predates the element.
function Hud.element(name: string): GuiObject
	local gui = Hud.get()
	local found = gui:FindFirstChild(name)
	if not found then
		gui = rebuild(gui.Parent :: Instance, `is missing "{name}"`)
		cached = gui
		found = gui:FindFirstChild(name)
	end
	return found :: GuiObject
end

return Hud
