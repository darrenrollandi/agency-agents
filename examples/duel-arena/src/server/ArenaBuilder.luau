--!strict
-- ArenaBuilder: constructs the Arena_Basic model in code. Run once via execute_luau (Edit) to create
-- ServerStorage.ArenaTemplates.Arena_Basic, then edit it visually in Studio. Arena.luau falls back to
-- build() if the template is missing so a forgotten place-save never blocks a playtest.
local ArenaBuilder = {}

ArenaBuilder.TemplateName = "Arena_Basic"

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
	end
end

-- A walled square arena with team spawns facing each other and two centre pillars for cover.
-- Pivot is the centre of the floor's top surface.
function ArenaBuilder.build(): Model
	local model = Instance.new("Model")
	model.Name = ArenaBuilder.TemplateName

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
	local pillarColor = Color3.fromRGB(120, 124, 136)
	local pillar = Vector3.new(4, 8, 4)
	part("Pillar1", pillar, CFrame.new(0, 4, -10), pillarColor, Enum.Material.SmoothPlastic, cover)
	part("Pillar2", pillar, CFrame.new(0, 4, 10), pillarColor, Enum.Material.SmoothPlastic, cover)

	spawns(model, "SpawnsA", -SPAWN_X, Color3.fromRGB(0, 170, 255))
	spawns(model, "SpawnsB", SPAWN_X, Color3.fromRGB(255, 120, 40))

	model.PrimaryPart = floor
	model.WorldPivot = CFrame.new()
	return model
end

return ArenaBuilder
