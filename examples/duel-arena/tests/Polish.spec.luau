--!strict
local Sounds = require(game:GetService("ReplicatedStorage").Shared.Config.Sounds)
local ArenaBuilder = require(game:GetService("ServerScriptService").Server.ArenaBuilder)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["every sound has a Roblox asset id and sane volume/speed"] = function(assertEqual: Assert)
		local count = 0
		for name, def in Sounds.Defs do
			count += 1
			local isAsset = def.id:match("^rbxasset://") ~= nil
				or def.id:match("^rbxassetid://%d+$") ~= nil
			assertEqual(isAsset, true, `{name} id`)
			assertEqual(def.volume >= 0 and def.volume <= 1, true, `{name} volume`)
			assertEqual(def.speed > 0, true, `{name} speed`)
		end
		for _, required in { "Fire", "Reload", "Swing", "Hit", "Kill", "Death", "Fight", "Tick" } do
			assertEqual(Sounds.Defs[required] ~= nil, true, `{required} defined`)
		end
		assertEqual(count >= 8, true, "enough sounds")
	end,

	["arena variants are unique and each builds a full shell"] = function(assertEqual: Assert)
		local seen = {}
		for _, name in ArenaBuilder.Variants do
			assertEqual(seen[name], nil, `duplicate {name}`)
			seen[name] = true
		end
		local models = ArenaBuilder.buildAll()
		assertEqual(#models, #ArenaBuilder.Variants, "one model per variant")
		for index, model in models do
			assertEqual(model.Name, ArenaBuilder.Variants[index], `name {index}`)
			assertEqual(
				#(model:FindFirstChild("SpawnsA") :: Folder):GetChildren(),
				4,
				`{model.Name} spawnsA`
			)
			assertEqual(
				#(model:FindFirstChild("SpawnsB") :: Folder):GetChildren(),
				4,
				`{model.Name} spawnsB`
			)
			assertEqual(
				#(model:FindFirstChild("Walls") :: Folder):GetChildren(),
				4,
				`{model.Name} walls`
			)
			assertEqual(
				#(model:FindFirstChild("Cover") :: Folder):GetChildren() > 0,
				true,
				`{model.Name} cover`
			)
			model:Destroy()
		end
	end,
}
