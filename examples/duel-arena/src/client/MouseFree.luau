--!strict
-- MouseFree: lets panels free the mouse in locked first person. The camera script re-locks the
-- cursor every frame, so while any holder is active we set it back to Default after the camera step.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BIND_NAME = "DuelArenaMouseFree"

local MouseFree = {}

local holders: { [string]: boolean } = {}
local bound = false

local function anyHolder(): boolean
	return next(holders) ~= nil
end

-- Keep the mouse free while `key` holds it.
function MouseFree.hold(key: string)
	holders[key] = true
	if bound then
		return
	end
	bound = true
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Last.Value, function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
end

-- Release `key`; the mouse re-locks when nobody holds it.
function MouseFree.release(key: string)
	holders[key] = nil
	if anyHolder() or not bound then
		return
	end
	bound = false
	RunService:UnbindFromRenderStep(BIND_NAME)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function MouseFree.isFree(): boolean
	return anyHolder()
end

return MouseFree
