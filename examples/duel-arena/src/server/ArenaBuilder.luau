--!strict
-- ArenaBuilder: constructs the arena templates in code. Run the setup snippet in STATUS.md once to
-- create ServerStorage.ArenaTemplates.<Variant>, then edit them visually in Studio. Arena.luau falls
-- back to buildAll() if the folder is empty so a forgotten place-save never blocks a playtest.
-- Every variant shares the shell (floor, walls, spawns); only the cover differs.
local ArenaBuilder = {}

ArenaBuilder.Variants = { "Arena_Basic", "Arena_Cross", "Arena_Crates" }
ArenaBuilder.TemplateName = ArenaBuilder.Variants[1]

local SIZE = 64
local WALL_HEIGHT = 24
local WALL_THICKNESS = 2
local SPAWN_X = 24
local SPAWNS_PER_TEAM = 4

local function part(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function spawns(parent: Instance, name: string, x: number, color: Color3)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	local facing = Vector3.new(-math.sign(x), 0, 0)
	for index = 1, SPAWNS_PER_TEAM do
		local z = -9 + (index - 1) * 6
		local position = Vector3.new(x, 0.5, z)
		local spawn = part(
			`Spawn{index}`,
			Vector3.new(4, 1, 4),
			CFrame.lookAt(position, position + facing),
			color,
			Enum.Material.Neon,
			folder
		)
		spawn.Transparency = 0.5
		spawn.CanCollide = false
		spawn.CanQuery = false -- never blocks a shot
	end
end

local function shell(name: string): (Model, Folder)
	local model = Instance.new("Model")
	model.Name = name

	local floor = part(
		"Floor",
		Vector3.new(SIZE, 2, SIZE),
		CFrame.new(0, -1, 0),
		Color3.fromRGB(72, 74, 82),
		Enum.Material.SmoothPlastic,
		model
	)

	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = model
	local wallColor = Color3.fromRGB(44, 46, 54)
	local concrete = Enum.Material.Concrete
	local offset = SIZE / 2 + WALL_THICKNESS / 2
	local y = WALL_HEIGHT / 2
	local long = Vector3.new(SIZE + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS)
	local side = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, SIZE)
	part("North", long, CFrame.new(0, y, -offset), wallColor, concrete, walls)
	part("South", long, CFrame.new(0, y, offset), wallColor, concrete, walls)
	part("East", side, CFrame.new(offset, y, 0), wallColor, concrete, walls)
	part("West", side, CFrame.new(-offset, y, 0), wallColor, concrete, walls)

	local cover = Instance.new("Folder")
	cover.Name = "Cover"
	cover.Parent = model

	spawns(model, "SpawnsA", -SPAWN_X, Color3.fromRGB(0, 170, 255))
	spawns(model, "SpawnsB", SPAWN_X, Color3.fromRGB(255, 120, 40))

	model.PrimaryPart = floor
	model.WorldPivot = CFrame.new()
	return model, cover
end

local PILLAR = Color3.fromRGB(120, 124, 136)
local CRATE = Color3.fromRGB(150, 120, 80)
local PLASTIC = Enum.Material.SmoothPlastic

local covers: { [string]: (Folder) -> () } = {
	-- Two centre pillars: the original.
	Arena_Basic = function(cover)
		local pillar = Vector3.new(4, 8, 4)
		part("Pillar1", pillar, CFrame.new(0, 4, -10), PILLAR, PLASTIC, cover)
		part("Pillar2", pillar, CFrame.new(0, 4, 10), PILLAR, PLASTIC, cover)
	end,
	-- A plus-shaped wall with a gap in the middle: four lanes, peeks at the centre.
	Arena_Cross = function(cover)
		local alongX = Vector3.new(8, 8, 2)
		local alongZ = Vector3.new(2, 8, 8)
		part("ArmEast", alongX, CFrame.new(10, 4, 0), PILLAR, PLASTIC, cover)
		part("ArmWest", alongX, CFrame.new(-10, 4, 0), PILLAR, PLASTIC, cover)
		part("ArmNorth", alongZ, CFrame.new(0, 4, -10), PILLAR, PLASTIC, cover)
		part("ArmSouth", alongZ, CFrame.new(0, 4, 10), PILLAR, PLASTIC, cover)
	end,
	-- Scattered crates to slide between, plus two tall posts.
	Arena_Crates = function(cover)
		local crate = Vector3.new(4, 4, 4)
		local positions = {
			Vector3.new(-10, 2, -8),
			Vector3.new(10, 2, -8),
			Vector3.new(-10, 2, 8),
			Vector3.new(10, 2, 8),
			Vector3.new(-18, 2, 0),
			Vector3.new(18, 2, 0),
		}
		for index, position in positions do
			part(
				`Crate{index}`,
				crate,
				CFrame.new(position),
				CRATE,
				Enum.Material.WoodPlanks,
				cover
			)
		end
		local post = Vector3.new(2, 10, 2)
		part("Post1", post, CFrame.new(0, 5, -14), PILLAR, PLASTIC, cover)
		part("Post2", post, CFrame.new(0, 5, 14), PILLAR, PLASTIC, cover)
	end,
}

-- One variant by name (defaults to Arena_Basic for unknown names).
function ArenaBuilder.build(name: string?): Model
	local variant = if name and covers[name] then name else ArenaBuilder.TemplateName
	local model, cover = shell(variant)
	covers[variant](cover)
	return model
end

-- Every variant, in Variants order.
function ArenaBuilder.buildAll(): { Model }
	local models = {}
	for _, name in ArenaBuilder.Variants do
		table.insert(models, ArenaBuilder.build(name))
	end
	return models
end

return ArenaBuilder
