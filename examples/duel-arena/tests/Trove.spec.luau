--!strict
local Trove = require(game:GetService("ReplicatedStorage").Shared.Util.Trove)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["clean runs callbacks in reverse order"] = function(assertEqual: Assert)
		local trove = Trove.new()
		local order = {}
		trove:add(function()
			table.insert(order, "first")
		end)
		trove:add(function()
			table.insert(order, "second")
		end)
		trove:clean()
		assertEqual(order[1], "second", "order[1]")
		assertEqual(order[2], "first", "order[2]")
	end,

	["clean destroys instances and disconnects connections"] = function(assertEqual: Assert)
		local trove = Trove.new()
		local part = trove:add(Instance.new("Part"))
		local fired = 0
		local event = Instance.new("BindableEvent")
		trove:connect(event.Event, function()
			fired += 1
		end)
		trove:clean()
		event:Fire()
		assertEqual(part.Parent, nil, "part.Parent")
		assertEqual(fired, 0, "fired")
		event:Destroy()
	end,

	["trove is reusable after clean"] = function(assertEqual: Assert)
		local trove = Trove.new()
		local count = 0
		trove:add(function()
			count += 1
		end)
		trove:clean()
		trove:add(function()
			count += 10
		end)
		trove:clean()
		assertEqual(count, 11, "count")
	end,
}
