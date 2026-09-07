--!strict
-- Arena: gives each duel its own arena, cloned from ServerStorage.ArenaTemplates into a free slot far
-- from the lobby, and destroys it on release. Arenas are never shared between duels.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rounds = require(Shared.Config.Rounds)
local Log = require(Shared.Util.Log)
local ArenaBuilder = require(script.Parent.ArenaBuilder)

export type ArenaInstance = {
	model: Model,
	slot: number,
	spawns: { A: { BasePart }, B: { BasePart } },
	release: () -> (),
}

local Arena = {}

local usedSlots: { [number]: boolean } = {}
local container: Folder? = nil

local function getContainer(): Folder
	local existing = container
	if existing and existing.Parent then
		return existing
	end
	local folder = Workspace:FindFirstChild("Arenas")
	if not folder or not folder:IsA("Folder") then
		folder = Instance.new("Folder")
		folder.Name = "Arenas"
		folder.Parent = Workspace
	end
	container = folder :: Folder
	return folder :: Folder
end

local function getTemplate(): Model
	local templates = ServerStorage:FindFirstChild("ArenaTemplates")
	local template = if templates then templates:FindFirstChild(ArenaBuilder.TemplateName) else nil
	if template and template:IsA("Model") then
		return template
	end
	Log.warn(
		`Arena: ServerStorage.ArenaTemplates.{ArenaBuilder.TemplateName} is missing; built it from`
			.. " ArenaBuilder. Run the P1 setup snippet in STATUS.md and save the place."
	)
	if not templates then
		templates = Instance.new("Folder")
		templates.Name = "ArenaTemplates"
		templates.Parent = ServerStorage
	end
	local built = ArenaBuilder.build()
	built.Parent = templates
	return built
end

local function spawnParts(model: Model, folderName: string): { BasePart }
	local parts: { BasePart } = {}
	local folder = model:FindFirstChild(folderName)
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(parts, child)
			end
		end
	end
	table.sort(parts, function(a, b)
		return a.Name < b.Name
	end)
	if #parts == 0 then
		Log.warn(`Arena: {model.Name} has no spawns under {folderName}; using the pivot`)
		local fallback = Instance.new("Part")
		fallback.Name = "FallbackSpawn"
		fallback.Anchored = true
		fallback.Transparency = 1
		fallback.CanCollide = false
		fallback.CFrame = model:GetPivot()
		fallback.Parent = model
		table.insert(parts, fallback)
	end
	return parts
end

-- Clone the template into a free slot. nil if every slot is in use.
function Arena.acquire(): ArenaInstance?
	local slot: number? = nil
	for index = 1, Rounds.MaxArenas do
		if not usedSlots[index] then
			slot = index
			break
		end
	end
	if not slot then
		Log.warn("Arena: no free slot; raise Config.Rounds.MaxArenas if this is legitimate")
		return nil
	end
	usedSlots[slot] = true

	local model = getTemplate():Clone()
	model.Name = `Arena_{slot}`
	model:PivotTo(
		CFrame.new(Rounds.ArenaOrigin + Vector3.new((slot - 1) * Rounds.ArenaSpacing, 0, 0))
	)
	model.Parent = getContainer()

	local released = false
	return {
		model = model,
		slot = slot,
		spawns = { A = spawnParts(model, "SpawnsA"), B = spawnParts(model, "SpawnsB") },
		release = function()
			if released then
				return
			end
			released = true
			usedSlots[slot :: number] = nil
			model:Destroy()
		end,
	}
end

return Arena
