--!strict
-- CameraController: first-person FOV and recoil. The engine's camera script positions the camera
-- first; we add the recoil pitch on top each frame so aim genuinely kicks and settles.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraConfig = require(Shared.Config.Camera)

local BIND_NAME = "DuelArenaRecoil"

local CameraController = {}

local recoilDegrees = 0
local fieldOfView = CameraConfig.FieldOfView

-- Kick the aim up by `degrees`; it recovers over the next frames.
function CameraController.kick(degrees: number)
	recoilDegrees += degrees
end

local function applyFov()
	Workspace.CurrentCamera.FieldOfView = fieldOfView
end

-- Settings panel: change the FOV (clamped to the Config/Camera range).
function CameraController.setFieldOfView(value: number)
	fieldOfView = math.clamp(value, CameraConfig.FieldOfViewMin, CameraConfig.FieldOfViewMax)
	applyFov()
end

function CameraController.getFieldOfView(): number
	return fieldOfView
end

function CameraController.start()
	applyFov()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyFov)
	RunService:BindToRenderStep(
		BIND_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		function(dt: number)
			if recoilDegrees <= 0.001 then
				recoilDegrees = 0
				return
			end
			recoilDegrees *= math.max(0, 1 - CameraConfig.RecoilRecoveryPerSecond * dt)
			local camera = Workspace.CurrentCamera
			camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(recoilDegrees), 0, 0)
		end
	)
end

return CameraController
