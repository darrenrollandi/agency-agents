--!strict
-- Trove: collects connections, instances, callbacks and destroyable tables,
-- then releases them all with one clean() call. Use one per round, character or player.
local Trove = {}
Trove.__index = Trove

export type Trove = typeof(setmetatable({} :: { _items: { any } }, Trove))

function Trove.new(): Trove
	return setmetatable({ _items = {} }, Trove)
end

-- Track an item; returns it so calls can be inlined.
function Trove.add<T>(self: Trove, item: T): T
	table.insert(self._items, item)
	return item
end

-- Connect to a signal and track the connection.
function Trove.connect(
	self: Trove,
	signal: RBXScriptSignal,
	callback: (...any) -> ()
): RBXScriptConnection
	return self:add(signal:Connect(callback))
end

-- Release everything in reverse insertion order. The trove is reusable afterwards.
function Trove.clean(self: Trove)
	local items = self._items
	self._items = {}
	for index = #items, 1, -1 do
		local item = items[index]
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "function" then
			item()
		elseif kind == "Instance" or (kind == "table" and typeof(item.Destroy) == "function") then
			item:Destroy()
		elseif kind == "table" and typeof(item.clean) == "function" then
			item:clean()
		end
	end
end

return Trove
