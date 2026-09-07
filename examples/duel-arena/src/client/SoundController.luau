--!strict
-- SoundController: plays Config/Sounds by name. play() is 2D (your own actions, UI); playAt() is 3D
-- at a world position (other players' shots, deaths). Every Sound instance destroys itself.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared.Config.Sounds)
local Log = require(Shared.Util.Log)

local SAFETY_SECONDS = 12

local SoundController = {}

local folder: Folder? = nil
local warned: { [string]: boolean } = {}

local function container(): Folder
	local existing = folder
	if existing and existing.Parent then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "DuelArenaSounds"
	created.Parent = SoundService
	folder = created
	return created
end

local function make(name: string): (Sound?, Sounds.SoundDef?)
	local def = Sounds.Defs[name]
	if not def then
		if not warned[name] then
			warned[name] = true
			Log.warn(`Sounds: no definition for "{name}"`)
		end
		return nil, nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = def.id
	sound.Volume = def.volume
	sound.PlaybackSpeed = def.speed
	return sound, def
end

local function fireAndForget(sound: Sound, extra: Instance?)
	sound.Ended:Once(function()
		sound:Destroy()
		if extra then
			extra:Destroy()
		end
	end)
	task.delay(SAFETY_SECONDS, function()
		if sound.Parent then
			sound:Destroy()
		end
		if extra and extra.Parent then
			extra:Destroy()
		end
	end)
	sound:Play()
end

-- 2D, full volume regardless of position.
function SoundController.play(name: string)
	local sound = make(name)
	if not sound then
		return
	end
	sound.Parent = container()
	fireAndForget(sound, nil)
end

-- 3D at `position`, rolling off over the sound's range.
function SoundController.playAt(name: string, position: Vector3)
	local sound, def = make(name)
	if not sound or not def then
		return
	end
	local emitter = Instance.new("Part")
	emitter.Name = `Sound_{name}`
	emitter.Size = Vector3.new(0.2, 0.2, 0.2)
	emitter.CFrame = CFrame.new(position)
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Parent = Workspace.CurrentCamera
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = def.range or 60
	sound.Parent = emitter
	fireAndForget(sound, emitter)
end

return SoundController
