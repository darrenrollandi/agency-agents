--!strict
-- Skins: cosmetic palettes for the code-built weapon models. A skin unlocks at a level, or via a
-- game pass (P6), or is a default everyone owns. Ids are stored in profiles, so never rename one.
local Types = require(script.Parent.Parent.Types)

export type Palette = {
	Grip: Color3,
	Body: Color3,
	Accent: Color3,
	Material: Enum.Material?,
}

export type SkinDef = {
	id: string,
	weapon: Types.WeaponId,
	name: string,
	-- Exactly one of these applies. Neither = default skin, always owned. Game-pass ids live in Config/Monetisation.
	unlockLevel: number?,
	gamePass: boolean?,
	palette: Palette,
}

local wood = Color3.fromRGB(45, 40, 38)
local gunmetal = Color3.fromRGB(70, 74, 82)
local steel = Color3.fromRGB(200, 205, 215)

local Defs: { SkinDef } = {
	-- Revolver
	{
		id = "RevolverDefault",
		weapon = "Revolver",
		name = "Standard Issue",
		palette = { Grip = wood, Body = gunmetal, Accent = steel },
	},
	{
		id = "RevolverBlued",
		weapon = "Revolver",
		name = "Blued Steel",
		unlockLevel = 2,
		palette = {
			Grip = Color3.fromRGB(30, 30, 34),
			Body = Color3.fromRGB(40, 60, 110),
			Accent = Color3.fromRGB(150, 170, 210),
		},
	},
	{
		id = "RevolverGold",
		weapon = "Revolver",
		name = "Gold Rush",
		unlockLevel = 5,
		palette = {
			Grip = Color3.fromRGB(90, 30, 30),
			Body = Color3.fromRGB(230, 180, 60),
			Accent = Color3.fromRGB(255, 220, 120),
			Material = Enum.Material.Metal,
		},
	},
	{
		id = "RevolverCrimson",
		weapon = "Revolver",
		name = "Crimson",
		unlockLevel = 8,
		palette = {
			Grip = Color3.fromRGB(20, 20, 20),
			Body = Color3.fromRGB(170, 30, 40),
			Accent = Color3.fromRGB(240, 90, 90),
			Material = Enum.Material.Neon,
		},
	},
	{
		id = "RevolverVoid",
		weapon = "Revolver",
		name = "Void",
		gamePass = true,
		palette = {
			Grip = Color3.fromRGB(10, 10, 14),
			Body = Color3.fromRGB(40, 20, 70),
			Accent = Color3.fromRGB(150, 80, 255),
			Material = Enum.Material.Neon,
		},
	},
	-- Knife
	{
		id = "KnifeDefault",
		weapon = "Knife",
		name = "Field Knife",
		palette = { Grip = wood, Body = steel, Accent = gunmetal },
	},
	{
		id = "KnifeJade",
		weapon = "Knife",
		name = "Jade",
		unlockLevel = 3,
		palette = {
			Grip = Color3.fromRGB(30, 40, 30),
			Body = Color3.fromRGB(60, 180, 120),
			Accent = Color3.fromRGB(200, 230, 200),
			Material = Enum.Material.Glass,
		},
	},
	{
		id = "KnifeObsidian",
		weapon = "Knife",
		name = "Obsidian",
		unlockLevel = 6,
		palette = {
			Grip = Color3.fromRGB(20, 20, 20),
			Body = Color3.fromRGB(30, 30, 40),
			Accent = Color3.fromRGB(120, 120, 140),
			Material = Enum.Material.Glass,
		},
	},
	{
		id = "KnifeNeon",
		weapon = "Knife",
		name = "Neon",
		unlockLevel = 10,
		palette = {
			Grip = Color3.fromRGB(20, 20, 30),
			Body = Color3.fromRGB(60, 240, 255),
			Accent = Color3.fromRGB(255, 80, 200),
			Material = Enum.Material.Neon,
		},
	},
	{
		id = "KnifeVoid",
		weapon = "Knife",
		name = "Void",
		gamePass = true,
		palette = {
			Grip = Color3.fromRGB(10, 10, 14),
			Body = Color3.fromRGB(150, 80, 255),
			Accent = Color3.fromRGB(40, 20, 70),
			Material = Enum.Material.Neon,
		},
	},
}

local byId: { [string]: SkinDef } = {}
for _, def in Defs do
	byId[def.id] = def
end

local Skins = {}
Skins.Defs = Defs

function Skins.get(id: string): SkinDef?
	return byId[id]
end

function Skins.forWeapon(weapon: Types.WeaponId): { SkinDef }
	local list = {}
	for _, def in Defs do
		if def.weapon == weapon then
			table.insert(list, def)
		end
	end
	return list
end

function Skins.defaultFor(weapon: Types.WeaponId): string
	return if weapon == "Revolver" then "RevolverDefault" else "KnifeDefault"
end

function Skins.isDefault(def: SkinDef): boolean
	return def.unlockLevel == nil and def.gamePass ~= true
end

-- Skins granted by reaching `level` (defaults included).
function Skins.unlockedAtLevel(level: number): { SkinDef }
	local list = {}
	for _, def in Defs do
		if Skins.isDefault(def) or (def.unlockLevel ~= nil and def.unlockLevel <= level) then
			table.insert(list, def)
		end
	end
	return list
end

return Skins
