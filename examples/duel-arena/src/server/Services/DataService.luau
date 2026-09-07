--!strict
-- DataService: the ProfileStore wrapper. One session-locked profile per player, loaded on join,
-- released on leave. In Studio (Config.UseMockData) it uses ProfileStore's in-memory Mock, so no
-- Studio session ever touches live DataStores. Nobody plays with unsaved data: a load failure kicks.
-- Profile.Data is only mutated by ProgressionService and MonetisationService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ProfileTemplate = require(Shared.Config.ProfileTemplate)
local Log = require(Shared.Util.Log)
local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)

export type Profile = ProfileStore.Profile<ProfileTemplate.ProfileData>

local STORE_NAME = "PlayerData_v1"
local LOAD_FAILED_MESSAGE = "Your data couldn't be loaded. Please rejoin in a moment."
local SESSION_TAKEN_MESSAGE = "Your data was opened on another server. Please rejoin."

local DataService = {}

local store = ProfileStore.New(STORE_NAME, ProfileTemplate)
if Config.UseMockData then
	store = store.Mock
end

local profiles: { [Player]: Profile } = {}
local loadedListeners: { (Player, Profile) -> () } = {}

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		if player.Parent == Players then
			Log.warn(`DataService: profile load failed for {player.Name}; kicking`)
			player:Kick(LOAD_FAILED_MESSAGE)
		end
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick(SESSION_TAKEN_MESSAGE)
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	local now = os.time()
	if profile.Data.FirstJoin == 0 then
		profile.Data.FirstJoin = now
	end
	profile.Data.LastJoin = now

	profiles[player] = profile
	Log.info(
		`DataService: profile loaded for {player.Name}{if Config.UseMockData then " (mock)" else ""}`
	)
	for _, listener in loadedListeners do
		task.spawn(listener, player, profile)
	end
end

-- The player's active profile, or nil while loading / after failure.
function DataService.getProfile(player: Player): Profile?
	local profile = profiles[player]
	if profile and profile:IsActive() then
		return profile
	end
	return nil
end

-- Register for profile loads. Fires for players already loaded too.
function DataService.onProfileLoaded(listener: (Player, Profile) -> ())
	table.insert(loadedListeners, listener)
	for player, profile in profiles do
		task.spawn(listener, player, profile)
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profiles[player] = nil
			profile:EndSession()
		end
	end)
end

return DataService
