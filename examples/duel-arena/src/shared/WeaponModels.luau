--!strict
-- WeaponModels: blocky placeholder geometry for the revolver and knife, built in code so the client
-- viewmodel and the server's third-person hand model share one source. Skins replace this in P4.
-- Every model's PrimaryPart is "Grip", centred on the model origin, and the weapon points along -Z.
-- Parts never collide or answer raycasts, so a weapon can't shield its owner.
local Types = require(script.Parent.Types)

local WeaponModels = {}

-- Muzzle/tip position relative to the Grip, for flashes and tracers.
WeaponModels.MuzzleOffset = {
	Revolver = Vector3.new(0, 0.75, -2.05),
	Knife = Vector3.new(0, 0.05, -1.95),
} :: { [Types.WeaponId]: Vector3 }

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	anchored: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Anchored = anchored
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weldTo(grip: BasePart, other: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = grip
	weld.Part1 = other
	weld.Parent = other
end

-- `anchored` = true for a viewmodel (moved with PivotTo), false for a hand-welded world model.
function WeaponModels.build(weapon: Types.WeaponId, anchored: boolean): Model
	local model = Instance.new("Model")
	model.Name = weapon
	local dark = Color3.fromRGB(45, 40, 38)
	local gunmetal = Color3.fromRGB(70, 74, 82)
	local steel = Color3.fromRGB(200, 205, 215)
	local metal = Enum.Material.Metal

	if weapon == "Revolver" then
		local grip = part(
			model,
			"Grip",
			Vector3.new(0.35, 0.9, 0.4),
			CFrame.new(),
			dark,
			Enum.Material.Wood,
			anchored
		)
		weldTo(
			grip,
			part(
				model,
				"Frame",
				Vector3.new(0.4, 0.5, 1.0),
				CFrame.new(0, 0.65, -0.45),
				gunmetal,
				metal,
				anchored
			)
		)
		weldTo(
			grip,
			part(
				model,
				"Cylinder",
				Vector3.new(0.5, 0.5, 0.5),
				CFrame.new(0, 0.65, -0.35),
				steel,
				metal,
				anchored
			)
		)
		weldTo(
			grip,
			part(
				model,
				"Barrel",
				Vector3.new(0.22, 0.22, 1.2),
				CFrame.new(0, 0.75, -1.45),
				gunmetal,
				metal,
				anchored
			)
		)
		weldTo(
			grip,
			part(
				model,
				"Hammer",
				Vector3.new(0.12, 0.3, 0.2),
				CFrame.new(0, 0.95, 0),
				steel,
				metal,
				anchored
			)
		)
		model.PrimaryPart = grip
	else
		local grip = part(
			model,
			"Grip",
			Vector3.new(0.3, 0.3, 0.9),
			CFrame.new(),
			dark,
			Enum.Material.Wood,
			anchored
		)
		weldTo(
			grip,
			part(
				model,
				"Guard",
				Vector3.new(0.6, 0.6, 0.12),
				CFrame.new(0, 0, -0.5),
				gunmetal,
				metal,
				anchored
			)
		)
		weldTo(
			grip,
			part(
				model,
				"Blade",
				Vector3.new(0.08, 0.35, 1.4),
				CFrame.new(0, 0.05, -1.25),
				steel,
				metal,
				anchored
			)
		)
		model.PrimaryPart = grip
	end

	return model
end

return WeaponModels
