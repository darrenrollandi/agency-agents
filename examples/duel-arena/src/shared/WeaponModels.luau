--!strict
-- WeaponModels: blocky placeholder geometry for the revolver and knife, built in code so the client
-- viewmodel and the server's third-person hand model share one source. Skins are palettes from
-- Config/Skins applied to the same geometry.
-- Every model's PrimaryPart is "Grip", centred on the model origin, and the weapon points along -Z.
-- Parts never collide or answer raycasts, so a weapon can't shield its owner.
local Types = require(script.Parent.Types)
local Skins = require(script.Parent.Config.Skins)

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
-- `skinId` falls back to the weapon's default skin when nil or unknown.
function WeaponModels.build(weapon: Types.WeaponId, anchored: boolean, skinId: string?): Model
	local skin = (if skinId then Skins.get(skinId) else nil) or Skins.get(Skins.defaultFor(weapon))
	local palette = (skin :: Skins.SkinDef).palette
	local bodyMaterial = palette.Material or Enum.Material.Metal

	local model = Instance.new("Model")
	model.Name = weapon
	model:SetAttribute("Skin", (skin :: Skins.SkinDef).id)

	if weapon == "Revolver" then
		local grip = part(
			model,
			"Grip",
			Vector3.new(0.35, 0.9, 0.4),
			CFrame.new(),
			palette.Grip,
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
				palette.Body,
				bodyMaterial,
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
				palette.Accent,
				Enum.Material.Metal,
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
				palette.Body,
				bodyMaterial,
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
				palette.Accent,
				Enum.Material.Metal,
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
			palette.Grip,
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
				palette.Accent,
				Enum.Material.Metal,
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
				palette.Body,
				bodyMaterial,
				anchored
			)
		)
		model.PrimaryPart = grip
	end

	return model
end

return WeaponModels
