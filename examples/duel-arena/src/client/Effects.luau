--!strict
-- Effects: throwaway client-only visuals (muzzle flash, tracer, impact). Parts live under the Camera,
-- never collide or answer raycasts, and destroy themselves.
local Workspace = game:GetService("Workspace")

local Effects = {}

local function container(): Instance
	local camera = Workspace.CurrentCamera
	local folder = camera:FindFirstChild("Effects")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Effects"
		folder.Parent = camera
	end
	return folder :: Instance
end

local function ephemeral(
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	transparency: number,
	life: number
): Part
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = container()
	task.delay(life, function()
		part:Destroy()
	end)
	return part
end

function Effects.flash(position: Vector3)
	local part = ephemeral(
		Vector3.new(0.35, 0.35, 0.35),
		CFrame.new(position),
		Color3.fromRGB(255, 220, 120),
		0,
		0.05
	)
	part.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range = 10
	light.Color = Color3.fromRGB(255, 200, 100)
	light.Parent = part
end

function Effects.tracer(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	if length < 0.5 then
		return
	end
	local midpoint = (from + to) / 2
	ephemeral(
		Vector3.new(0.05, 0.05, length),
		CFrame.lookAt(midpoint, to),
		Color3.fromRGB(255, 235, 170),
		0.25,
		0.07
	)
end

function Effects.impact(position: Vector3)
	ephemeral(
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(position),
		Color3.fromRGB(255, 255, 255),
		0.1,
		0.12
	)
end

return Effects
