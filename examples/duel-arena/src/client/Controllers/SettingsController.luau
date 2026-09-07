--!strict
-- SettingsController: the Tab settings panel (mouse sensitivity, field of view). Values apply
-- instantly, load from the ProgressionSnapshot and save to the profile via SaveSettings (debounced).
-- Works with the arrow buttons (mouse freed while open) or the keyboard: ↑ ↓ pick a row, ← → adjust.
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local CameraConfig = require(Shared.Config.Camera)
local Net = require(Shared.Net.Net)
local Hud = require(script.Parent.Parent.Hud)
local MouseFree = require(script.Parent.Parent.MouseFree)
local CameraController = require(script.Parent.CameraController)

local ACTION_TOGGLE = "ToggleSettings"
local ACTION_NAV = "SettingsNavigate"
local HOLD_KEY = "Settings"
local SAVE_DEBOUNCE = 0.6

local SettingsController = {}

local panel: Frame
local sensitivityRow: TextLabel
local fovRow: TextLabel
local sensitivity = CameraConfig.Sensitivity
local fieldOfView = CameraConfig.FieldOfView
local selectedRow = 1
local open = false
local saveToken = 0

local function apply()
	UserInputService.MouseDeltaSensitivity = sensitivity
	CameraController.setFieldOfView(fieldOfView)
end

local function render()
	local s = if selectedRow == 1 then "▸ " else "   "
	local f = if selectedRow == 2 then "▸ " else "   "
	sensitivityRow.Text = `{s}Sensitivity      {string.format("%.1f", sensitivity)}`
	fovRow.Text = `{f}Field of view     {fieldOfView}`
end

local function scheduleSave()
	saveToken += 1
	local token = saveToken
	task.delay(SAVE_DEBOUNCE, function()
		if token == saveToken then
			Net.fireServer("SaveSettings", sensitivity, fieldOfView)
		end
	end)
end

local function adjustSensitivity(direction: number)
	local next = sensitivity + direction * CameraConfig.SensitivityStep
	sensitivity = math.clamp(
		math.round(next * 10) / 10,
		CameraConfig.SensitivityMin,
		CameraConfig.SensitivityMax
	)
	apply()
	render()
	scheduleSave()
end

local function adjustFov(direction: number)
	local next = fieldOfView + direction * CameraConfig.FieldOfViewStep
	fieldOfView = math.clamp(next, CameraConfig.FieldOfViewMin, CameraConfig.FieldOfViewMax)
	apply()
	render()
	scheduleSave()
end

local function adjustSelected(direction: number)
	if selectedRow == 1 then
		adjustSensitivity(direction)
	else
		adjustFov(direction)
	end
end

local function onNavigate(_name: string, inputState: Enum.UserInputState, input: InputObject)
	if inputState ~= Enum.UserInputState.Begin or not open then
		return Enum.ContextActionResult.Pass
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp then
		selectedRow = 1
	elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.DPadDown then
		selectedRow = 2
	elseif key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft then
		adjustSelected(-1)
	elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.DPadRight then
		adjustSelected(1)
	end
	render()
	return Enum.ContextActionResult.Sink
end

local function setOpen(value: boolean)
	if open == value then
		return
	end
	open = value
	panel.Visible = value
	panel:SetAttribute("Open", value)
	if value then
		render()
		MouseFree.hold(HOLD_KEY)
		ContextActionService:BindAction(
			ACTION_NAV,
			onNavigate,
			false,
			Enum.KeyCode.Up,
			Enum.KeyCode.Down,
			Enum.KeyCode.Left,
			Enum.KeyCode.Right,
			Enum.KeyCode.DPadUp,
			Enum.KeyCode.DPadDown,
			Enum.KeyCode.DPadLeft,
			Enum.KeyCode.DPadRight
		)
	else
		MouseFree.release(HOLD_KEY)
		ContextActionService:UnbindAction(ACTION_NAV)
	end
end

local function onToggle(_name: string, inputState: Enum.UserInputState, _input: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	setOpen(not open)
	return Enum.ContextActionResult.Sink
end

-- Open or close from other UI.
function SettingsController.setOpen(value: boolean)
	setOpen(value)
end

function SettingsController.start()
	panel = Hud.element("SettingsPanel") :: Frame
	sensitivityRow = Hud.element("SensitivityRow") :: TextLabel
	fovRow = Hud.element("FovRow") :: TextLabel
	panel:SetAttribute("Open", false)
	panel:GetAttributeChangedSignal("Open"):Connect(function()
		setOpen(panel:GetAttribute("Open") == true)
	end)

	local buttons: { [string]: () -> () } = {
		SensitivityMinus = function()
			adjustSensitivity(-1)
		end,
		SensitivityPlus = function()
			adjustSensitivity(1)
		end,
		FovMinus = function()
			adjustFov(-1)
		end,
		FovPlus = function()
			adjustFov(1)
		end,
	}
	for name, handler in buttons do
		local button = Hud.element(name) :: TextButton
		button.Activated:Connect(handler)
	end

	Net.onClient("ProgressionSnapshot", function(snapshot: Types.ProgressionSnapshot)
		sensitivity = math.clamp(
			snapshot.sensitivity,
			CameraConfig.SensitivityMin,
			CameraConfig.SensitivityMax
		)
		fieldOfView = math.clamp(
			snapshot.fieldOfView,
			CameraConfig.FieldOfViewMin,
			CameraConfig.FieldOfViewMax
		)
		apply()
		if open then
			render()
		end
	end)

	apply()
	render()
	ContextActionService:BindAction(
		ACTION_TOGGLE,
		onToggle,
		false,
		Enum.KeyCode.Tab,
		Enum.KeyCode.ButtonStart
	)
end

return SettingsController
