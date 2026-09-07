--!strict
-- Config: environment flags. Tunables live in sibling modules (Weapons, Rounds, XP, ...).
local RunService = game:GetService("RunService")

local Config = {
	-- Log.debug output. On in Studio, off in a live server.
	Debug = RunService:IsStudio(),
	-- When true, DataService never touches DataStores. Must stay true until P4.
	UseMockData = RunService:IsStudio(),
}

return Config
