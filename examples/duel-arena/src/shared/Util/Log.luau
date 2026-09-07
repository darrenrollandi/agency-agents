--!strict
-- Log: levelled logging. debug() is silent unless Config.Debug is true.
local Config = require(script.Parent.Parent.Config)

local Log = {}

-- Development-only output; no-op outside Studio.
function Log.debug(...: any)
	if Config.Debug then
		print("[DEBUG]", ...)
	end
end

-- Normal operational output (state transitions, service start).
function Log.info(...: any)
	print("[INFO]", ...)
end

-- Recoverable runtime/network problems. Keep going after calling this.
function Log.warn(...: any)
	warn("[WARN]", ...)
end

-- Programmer mistakes. Raises; do not use for player-caused conditions.
function Log.error(message: string, level: number?): never
	error(message, (level or 1) + 1)
end

return Log
