--!strict
-- ProgressionService: XP, levels, skin unlocks and equipped skins. The only code that writes
-- progression fields on Profile.Data. Publishes Level / XP / EquippedRevolver / EquippedKnife as
-- Player attributes for cheap reads and a ProgressionSnapshot for the locker.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local XP = require(Shared.Config.XP)
local Skins = require(Shared.Config.Skins)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local DataService = require(script.Parent.DataService)
local CombatService = require(script.Parent.CombatService)

export type DuelResult = {
	player: Player,
	won: boolean,
	roundsWon: number,
}

local ProgressionService = {}

local function boostActive(profile: DataService.Profile): boolean
	return profile.Data.XPBoostUntil > os.time()
end

local function snapshot(profile: DataService.Profile): Types.ProgressionSnapshot
	local owned = {}
	for skinId in profile.Data.OwnedSkins do
		table.insert(owned, skinId)
	end
	table.sort(owned)
	local level = XP.levelForXP(profile.Data.XP)
	return {
		xp = profile.Data.XP,
		level = level,
		nextLevelXP = XP.xpForLevel(math.min(level + 1, XP.MaxLevel)),
		wins = profile.Data.Wins,
		losses = profile.Data.Losses,
		owned = owned,
		equippedRevolver = profile.Data.EquippedRevolver,
		equippedKnife = profile.Data.EquippedKnife,
		boostActive = boostActive(profile),
		sensitivity = profile.Data.Settings.Sensitivity,
		fieldOfView = profile.Data.Settings.FieldOfView,
	}
end

local function publish(player: Player, profile: DataService.Profile)
	player:SetAttribute("XP", profile.Data.XP)
	player:SetAttribute("Level", XP.levelForXP(profile.Data.XP))
	player:SetAttribute("EquippedRevolver", profile.Data.EquippedRevolver)
	player:SetAttribute("EquippedKnife", profile.Data.EquippedKnife)
	Net.fireClient(player, "ProgressionSnapshot", snapshot(profile))
end

-- Grants every skin the player's level entitles them to. Returns the newly unlocked ids.
local function grantLevelSkins(profile: DataService.Profile): { string }
	local unlocked = {}
	for _, def in Skins.unlockedAtLevel(XP.levelForXP(profile.Data.XP)) do
		if not profile.Data.OwnedSkins[def.id] then
			profile.Data.OwnedSkins[def.id] = true
			if not Skins.isDefault(def) then
				table.insert(unlocked, def.id)
			end
		end
	end
	return unlocked
end

local function onProfileLoaded(player: Player, profile: DataService.Profile)
	grantLevelSkins(profile)
	-- Heal a profile whose equipped skin was removed from Config/Skins.
	if not Skins.get(profile.Data.EquippedRevolver) then
		profile.Data.EquippedRevolver = Skins.defaultFor("Revolver")
	end
	if not Skins.get(profile.Data.EquippedKnife) then
		profile.Data.EquippedKnife = Skins.defaultFor("Knife")
	end
	publish(player, profile)
end

-- True once the player's data is loaded; Matchmaking refuses to queue anyone before that.
function ProgressionService.isReady(player: Player): boolean
	return DataService.getProfile(player) ~= nil
end

-- Equipped skin id for a weapon (default if unknown / unloaded).
function ProgressionService.getEquippedSkin(player: Player, weapon: Types.WeaponId): string
	local profile = DataService.getProfile(player)
	if not profile then
		return Skins.defaultFor(weapon)
	end
	return if weapon == "Revolver"
		then profile.Data.EquippedRevolver
		else profile.Data.EquippedKnife
end

-- Give a skin outright (game pass, promo). Idempotent.
function ProgressionService.grantSkin(player: Player, skinId: string): boolean
	local profile = DataService.getProfile(player)
	local def = Skins.get(skinId)
	if not profile or not def then
		return false
	end
	if not profile.Data.OwnedSkins[skinId] then
		profile.Data.OwnedSkins[skinId] = true
		publish(player, profile)
	end
	return true
end

-- Add XP directly (debug, promos). Returns the reward summary.
function ProgressionService.addXP(player: Player, amount: number): Types.DuelReward?
	local profile = DataService.getProfile(player)
	if not profile or amount <= 0 then
		return nil
	end
	local before = XP.levelForXP(profile.Data.XP)
	profile.Data.XP = math.min(profile.Data.XP + math.floor(amount), XP.xpForLevel(XP.MaxLevel))
	local after = XP.levelForXP(profile.Data.XP)
	local unlocked = grantLevelSkins(profile)
	publish(player, profile)
	if after > before then
		Log.info(`Progression: {player.Name} reached level {after}`)
	end
	return {
		won = false,
		xpGained = amount,
		boosted = false,
		level = after,
		leveledUp = after > before,
		unlocked = unlocked,
	}
end

-- Record a finished duel for every participant still on the server. DuelService calls this once.
function ProgressionService.recordDuel(results: { DuelResult })
	for _, result in results do
		local player = result.player
		local profile = DataService.getProfile(player)
		if not profile or player.Parent ~= Players then
			continue
		end
		local boosted = boostActive(profile)
		local gained = XP.forDuel(result.won, result.roundsWon)
		if boosted then
			gained *= XP.BoostMultiplier
		end
		profile.Data.Duels += 1
		profile.Data.RoundsWon += result.roundsWon
		if result.won then
			profile.Data.Wins += 1
		else
			profile.Data.Losses += 1
		end
		local reward = ProgressionService.addXP(player, gained)
		if reward then
			reward.won = result.won
			reward.boosted = boosted
			Net.fireClient(player, "DuelReward", reward)
		end
	end
end

local function onEquipSkin(player: Player, skinId: string)
	local profile = DataService.getProfile(player)
	local def = Skins.get(skinId)
	if not profile or not def or not profile.Data.OwnedSkins[skinId] then
		return
	end
	if def.weapon == "Revolver" then
		profile.Data.EquippedRevolver = skinId
	else
		profile.Data.EquippedKnife = skinId
	end
	publish(player, profile)
	CombatService.refreshWorldModel(player)
end

-- Settings are validated for range by the Net definition; here we just persist them.
local function onSaveSettings(player: Player, sensitivity: number, fieldOfView: number)
	local profile = DataService.getProfile(player)
	if not profile then
		return
	end
	profile.Data.Settings.Sensitivity = math.round(sensitivity * 100) / 100
	profile.Data.Settings.FieldOfView = math.round(fieldOfView)
end

function ProgressionService.start()
	DataService.onProfileLoaded(onProfileLoaded)
	Net.onServer("EquipSkin", onEquipSkin)
	Net.onServer("SaveSettings", onSaveSettings)
end

return ProgressionService
